import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/health_benefits.dart';
import '../../../core/theme.dart';
import '../../streak/providers/streak_provider.dart';
import '../providers/wallet_early_withdraw_provider.dart';
import '../providers/wallet_home_provider.dart';

const _confirmPhrase = 'I UNDERSTAND';
final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class WalletEarlyWithdrawalScreen extends ConsumerStatefulWidget {
  const WalletEarlyWithdrawalScreen({super.key, required this.habitId});
  final String habitId;

  @override
  ConsumerState<WalletEarlyWithdrawalScreen> createState() =>
      _WalletEarlyWithdrawalScreenState();
}

class _WalletEarlyWithdrawalScreenState
    extends ConsumerState<WalletEarlyWithdrawalScreen> {
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isConfirmed => _confirmCtrl.text == _confirmPhrase;

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(goalWalletProvider(widget.habitId));
    final currentStreak = ref.watch(currentStreakProvider);
    final withdrawState = ref.watch(walletEarlyWithdrawProvider);

    ref.listen<WalletEarlyWithdrawState>(walletEarlyWithdrawProvider, (previous, next) {
      if (next.status == WalletEarlyWithdrawStatus.success) {
        ref.invalidate(goalWalletProvider(widget.habitId));
        _snack('Wallet withdrawn early. Your progress has been reset.');
        var popped = 0;
        while (context.canPop() && popped < 2) {
          context.pop();
          popped++;
        }
      } else if (next.status == WalletEarlyWithdrawStatus.error) {
        _snack(next.errorMessage ?? 'Something went wrong');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Withdraw Early')),
      body: walletAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(child: Text('Failed to load wallet: $error')),
        data: (wallet) {
          if (wallet == null) {
            return const Center(child: Text('Wallet not found.'));
          }
          final milestone = unlockedBenefits(currentStreak).last;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  "This friction is intentional.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Withdrawing now means giving up everything below.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _ConsequenceRow(
                  emoji: '💸',
                  title: '${_fmt.format(wallet.currentBalance)} forfeited',
                  detail: "You won't receive this money — it's simply lost.",
                ),
                const SizedBox(height: 12),
                _ConsequenceRow(
                  emoji: '🔥',
                  title: '$currentStreak-day streak broken',
                  detail: 'Your streak resets to 0. Your longest streak stays on record.',
                ),
                const SizedBox(height: 12),
                _ConsequenceRow(
                  emoji: milestone.$2.emoji,
                  title: '"${milestone.$2.title}" marked as reset',
                  detail: 'This health milestone will no longer show as unlocked.',
                ),
                const SizedBox(height: 28),
                Text(
                  'Type "$_confirmPhrase" to confirm',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmCtrl,
                  decoration: const InputDecoration(hintText: _confirmPhrase),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConfirmed &&
                            withdrawState.status != WalletEarlyWithdrawStatus.submitting
                        ? () => ref
                            .read(walletEarlyWithdrawProvider.notifier)
                            .confirmEarlyWithdrawal(widget.habitId)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: withdrawState.status == WalletEarlyWithdrawStatus.submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Withdraw and reset my progress'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConsequenceRow extends StatelessWidget {
  const _ConsequenceRow({
    required this.emoji,
    required this.title,
    required this.detail,
  });

  final String emoji;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
