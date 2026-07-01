import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../habits/models/habit_model.dart';
import '../../habits/providers/habits_provider.dart';
import '../models/goal_wallet_model.dart';
import '../providers/wallet_list_provider.dart';

final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(userWalletsProvider);
    final habits = ref.watch(habitNotifierProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addWallet(context, habits, walletsAsync.value ?? []),
        child: const Icon(Icons.add),
      ),
      body: walletsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(child: Text('Failed to load wallets: $error')),
        data: (wallets) {
          if (wallets.isEmpty) {
            return const _EmptyState(
              message: 'No goal wallets yet — tap + to start one.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: wallets.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _WalletListCard(wallet: wallets[i]),
          );
        },
      ),
    );
  }

  void _addWallet(
    BuildContext context,
    List<HabitModel> habits,
    List<GoalWalletModel> wallets,
  ) {
    final walletedHabitIds = wallets.map((w) => w.habitId).toSet();
    final eligible = habits
        .where((h) => h.isActive && !walletedHabitIds.contains(h.id))
        .toList();

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('All your active habits already have a goal wallet.'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }

    if (eligible.length == 1) {
      context.push('/wallet/create', extra: eligible.first.id);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a habit',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...eligible.map(
              (habit) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_habitLabel(habit)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/wallet/create', extra: habit.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _habitLabel(HabitModel habit) {
    final name = habit.type.name;
    final spaced = name.replaceAllMapped(
      RegExp('([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _WalletListCard extends StatelessWidget {
  const _WalletListCard({required this.wallet});
  final GoalWalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/wallet/detail', extra: wallet.habitId),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.goalName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmt.format(wallet.currentBalance)} / ${_fmt.format(wallet.targetAmount)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: (wallet.progressPercent / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${wallet.progressPercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
