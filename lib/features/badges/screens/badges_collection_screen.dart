import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/badges.dart';
import '../../../core/theme.dart';
import '../../streak/providers/streak_provider.dart';
import '../../wallet/providers/wallet_list_provider.dart';
import '../providers/earned_badges_provider.dart';

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM yyyy');

/// Picks the current progress toward [badge]'s threshold, as a 0..1
/// fraction. Returns null for `custom`-trigger badges, which have no
/// continuous stat to measure progress against.
double? _progressFraction(
  BadgeModel badge, {
  required int dayCount,
  required int streakLength,
  required double savingsAmount,
}) {
  final current = switch (badge.triggerCondition) {
    BadgeTriggerCondition.dayCount => dayCount.toDouble(),
    BadgeTriggerCondition.streakLength => streakLength.toDouble(),
    BadgeTriggerCondition.savingsAmount => savingsAmount,
    BadgeTriggerCondition.custom => null,
  };
  if (current == null) return null;
  return (current / badge.thresholdValue).clamp(0, 1).toDouble();
}

String _hintFor(BadgeModel badge) {
  final threshold = badge.thresholdValue.toInt();
  return switch (badge.triggerCondition) {
    BadgeTriggerCondition.dayCount => 'Stay smoke-free for $threshold days',
    BadgeTriggerCondition.streakLength => 'Reach a $threshold-day streak',
    BadgeTriggerCondition.savingsAmount =>
      'Save ${_currencyFmt.format(badge.thresholdValue)} in your wallet',
    BadgeTriggerCondition.custom => badge.description,
  };
}

class BadgesCollectionScreen extends ConsumerWidget {
  const BadgesCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(earnedBadgesProvider).value ?? const {};
    final streak = ref.watch(streakProvider);
    final totalSavings = ref.watch(totalSavingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Badges')),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: badges.length,
        itemBuilder: (_, i) {
          final badge = badges[i];
          return _BadgeTile(
            badge: badge,
            earnedAt: earned[badge.id],
            progress: _progressFraction(
              badge,
              dayCount: streak.totalCleanDays,
              streakLength: streak.currentStreak,
              savingsAmount: totalSavings,
            ),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earnedAt, required this.progress});

  final BadgeModel badge;
  final DateTime? earnedAt;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final isEarned = earnedAt != null;

    final icon = Image.asset(
      badge.iconPath,
      width: 56,
      height: 56,
      errorBuilder: (_, _, _) => Icon(
        Icons.emoji_events,
        size: 48,
        color: isEarned ? AppColors.primary : AppColors.textSecondary,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              isEarned
                  ? icon
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                      child: Opacity(opacity: 0.5, child: icon),
                    ),
              if (!isEarned)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: _LockBadge(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isEarned ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (isEarned)
            Text(
              'Earned ${_dateFmt.format(earnedAt!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              _hintFor(badge),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.lock, size: 12, color: Colors.white),
    );
  }
}
