import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../habits/models/habit_model.dart';
import '../habit_display.dart';

class EditHabitsScreen extends ConsumerStatefulWidget {
  const EditHabitsScreen({super.key});

  @override
  ConsumerState<EditHabitsScreen> createState() => _EditHabitsScreenState();
}

class _EditHabitsScreenState extends ConsumerState<EditHabitsScreen> {
  late final List<HabitType> _habitTypes;
  late final Map<HabitType, TextEditingController> _qtyControllers;
  late final Map<HabitType, TextEditingController> _costControllers;
  DateTime? _quitDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).asData?.value;
    final meta = user?.userMetadata ?? {};

    _habitTypes = parseHabitTypes(meta['habit_types']);
    final details = parseHabitDetails(meta['habit_details']);

    _qtyControllers = {
      for (final type in _habitTypes)
        type: TextEditingController(text: '${details[type]?.dailyQty ?? 5}'),
    };
    _costControllers = {
      for (final type in _habitTypes)
        type: TextEditingController(text: '${details[type]?.unitCost ?? 0}'),
    };

    final quitDateRaw = meta['quit_date'] as String?;
    _quitDate = quitDateRaw != null ? DateTime.tryParse(quitDateRaw) : null;
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _costControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickQuitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _quitDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _quitDate = picked);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final currentMeta = client.auth.currentUser?.userMetadata ?? {};

      final updatedDetails = {
        for (final type in _habitTypes)
          type.name: {
            'daily_qty': int.tryParse(_qtyControllers[type]!.text.trim()) ?? 0,
            'unit_cost': double.tryParse(_costControllers[type]!.text.trim()) ?? 0.0,
          },
      };

      await client.auth.updateUser(UserAttributes(data: {
        ...currentMeta,
        'habit_details': updatedDetails,
        'quit_date': (_quitDate ?? DateTime.now()).toIso8601String(),
      }));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Habits')),
      body: _habitTypes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No habits to edit yet.',
                  style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final type in _habitTypes) ...[
                  _HabitEditCard(
                    type: type,
                    qtyController: _qtyControllers[type]!,
                    costController: _costControllers[type]!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _QuitDateRow(quitDate: _quitDate, onTap: _pickQuitDate),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
    );
  }
}

class _HabitEditCard extends StatelessWidget {
  const _HabitEditCard({
    required this.type,
    required this.qtyController,
    required this.costController,
  });

  final HabitType type;
  final TextEditingController qtyController;
  final TextEditingController costController;

  @override
  Widget build(BuildContext context) {
    final info = habitDisplayInfo[type]!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                info.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Daily ${info.unit}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cost per unit (₹)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuitDateRow extends StatelessWidget {
  const _QuitDateRow({required this.quitDate, required this.onTap});

  final DateTime? quitDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Quit date',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              quitDate != null ? DateFormat('d MMM yyyy').format(quitDate!) : 'Not set',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
