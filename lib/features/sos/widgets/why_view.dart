import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../wallet/providers/wallet_list_provider.dart';

class WhyView extends ConsumerWidget {
  const WhyView({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final walletsAsync = ref.watch(userWalletsProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final wallets = walletsAsync.value ?? const [];
    final wallet = wallets.isEmpty ? null : wallets.first;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
        ),
        const Spacer(),
        Text(
          '${data.streakEmoji} ${data.daysClean} days clean',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "You're breaking free from ${data.habitType}.",
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (wallet != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  '"${wallet.goalName}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${fmt.format(wallet.currentBalance)} saved of ${fmt.format(wallet.targetAmount)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: (wallet.progressPercent / 100).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          )
        else
          const Text(
            'Every clean day is money and health back in your hands.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Text(
            "This is what you're fighting for. You've got this.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
