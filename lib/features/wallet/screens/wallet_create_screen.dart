import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../habits/models/habit_model.dart';
import '../../habits/providers/habits_provider.dart';
import '../providers/wallet_create_provider.dart';

final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM yyyy');

class WalletCreateScreen extends ConsumerStatefulWidget {
  const WalletCreateScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<WalletCreateScreen> createState() => _WalletCreateScreenState();
}

class _WalletCreateScreenState extends ConsumerState<WalletCreateScreen> {
  final _goalNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _goalNameCtrl.addListener(_refresh);
    _amountCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _goalNameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _isValid =>
      _goalNameCtrl.text.trim().isNotEmpty &&
      (double.tryParse(_amountCtrl.text.trim()) ?? 0) > 0 &&
      _targetDate != null;

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? null : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Select your target date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit(String habitId) {
    if (!_isValid) return;
    ref.read(walletCreateProvider.notifier).createWallet(
          habitId: habitId,
          goalName: _goalNameCtrl.text.trim(),
          targetAmount: double.parse(_amountCtrl.text.trim()),
          targetDate: _targetDate!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitNotifierProvider);
    final createState = ref.watch(walletCreateProvider);

    ref.listen<WalletCreateState>(walletCreateProvider, (previous, next) {
      if (next.status == WalletCreateStatus.success) {
        _snack('Goal wallet locked! 🔒');
        context.pop();
      } else if (next.status == WalletCreateStatus.error) {
        _snack(next.errorMessage ?? 'Something went wrong', isError: true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Goal Wallet'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: habitsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text('Failed to load habit: $error'),
        ),
        data: (habits) {
          final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
          if (habit == null) {
            return const Center(child: Text('Habit not found.'));
          }
          return _buildForm(habit, createState);
        },
      ),
    );
  }

  Widget _buildForm(HabitModel habit, WalletCreateState createState) {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final dailySpend = habit.dailySpend;
    final days = (amount > 0 && dailySpend > 0) ? (amount / dailySpend).ceil() : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Goal name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _goalNameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. New phone'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FieldLabel('Target amount'),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FieldLabel('Target date'),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _targetDate != null ? _dateFmt.format(_targetDate!) : 'Select date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: _targetDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (days != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'At your current savings rate of ${_fmt.format(dailySpend)}/day, '
                "you'll reach this goal in $days days.",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Lock my wallet',
            onPressed: _isValid ? () => _submit(habit.id) : null,
            isLoading: createState.status == WalletCreateStatus.submitting,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
