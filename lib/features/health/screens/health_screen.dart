import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health_benefits.dart';
import '../../../core/theme.dart';
import '../../streak/providers/streak_provider.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysClean = ref.watch(currentStreakProvider);

    final sortedKeys = healthBenefits.keys.toList()..sort();
    final groupedEntries =
        sortedKeys.map((day) => (day, healthBenefits[day]!)).toList();

    // Highest milestone day the user has reached (-1 if none yet).
    int currentDay = -1;
    for (final day in sortedKeys) {
      if (day <= daysClean) currentDay = day;
    }

    final nextEntry = nextBenefit(daysClean);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HealthHeader(daysClean: daysClean),
          ),
          if (nextEntry != null)
            SliverToBoxAdapter(
              child: _NextUnlockCard(
                day: nextEntry.$1,
                benefit: nextEntry.$2,
                daysClean: daysClean,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xxl,
            ),
            sliver: SliverList.builder(
              itemCount: groupedEntries.length,
              itemBuilder: (context, index) {
                final (day, benefits) = groupedEntries[index];
                return _TimelineItem(
                  day: day,
                  benefits: benefits,
                  isUnlocked: day <= daysClean,
                  isCurrent: day == currentDay,
                  isFirst: index == 0,
                  isLast: index == groupedEntries.length - 1,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({required this.daysClean});

  final int daysClean;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D38), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.mobileMargin,
            AppSpacing.lg,
            AppSpacing.mobileMargin,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Health Journey',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$daysClean days',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                daysClean == 0
                    ? 'Start your journey to unlock milestones'
                    : 'Milestones unlocked on your path to recovery',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Next Unlock Card ──────────────────────────────────────────────────────────

class _NextUnlockCard extends StatelessWidget {
  const _NextUnlockCard({
    required this.day,
    required this.benefit,
    required this.daysClean,
  });

  final int day;
  final HealthBenefit benefit;
  final int daysClean;

  @override
  Widget build(BuildContext context) {
    final daysToGo = day - daysClean;
    final dayLabel = daysToGo == 1 ? 'day' : 'days';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.mobileMargin,
        AppSpacing.lg,
        AppSpacing.mobileMargin,
        0,
      ),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.successTint,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            benefit.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next unlock · $daysToGo $dayLabel away',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              benefit.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Day $day',
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
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ── Timeline Item ─────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.day,
    required this.benefits,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  final int day;
  final List<HealthBenefit> benefits;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final lineColor = isUnlocked
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: connector line + day badge.
          // SizedBox(72) with center-aligned Column puts badge left-edge at
          // exactly mobileMargin (20 px) from the screen edge.
          SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                _DayBadge(
                  day: day,
                  isUnlocked: isUnlocked,
                  isCurrent: isCurrent,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
              ],
            ),
          ),
          // Right: one or more benefit cards for this day.
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                8,
                AppSpacing.mobileMargin,
                isLast ? 0 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < benefits.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _BenefitCard(
                      benefit: benefits[i],
                      isUnlocked: isUnlocked,
                      isCurrent: isCurrent,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: (index % 8) * 60),
          duration: const Duration(milliseconds: 350),
        )
        .slideX(
          begin: 0.15,
          end: 0,
          curve: Curves.easeOutCubic,
          delay: Duration(milliseconds: (index % 8) * 60),
          duration: const Duration(milliseconds: 350),
        );
  }
}

// ── Day Badge ─────────────────────────────────────────────────────────────────

class _DayBadge extends StatelessWidget {
  const _DayBadge({
    required this.day,
    required this.isUnlocked,
    required this.isCurrent,
  });

  final int day;
  final bool isUnlocked;
  final bool isCurrent;

  String get _label {
    if (day >= 365) return '${day ~/ 365}yr';
    return 'D$day';
  }

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 38.0 : 32.0;

    BoxDecoration decoration;
    Color textColor;

    if (isCurrent) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );
      textColor = Colors.white;
    } else if (isUnlocked) {
      decoration = const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      );
      textColor = Colors.white;
    } else {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      );
      textColor = AppColors.textSecondary;
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ── Benefit Card ──────────────────────────────────────────────────────────────

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.benefit,
    required this.isUnlocked,
    required this.isCurrent,
  });

  final HealthBenefit benefit;
  final bool isUnlocked;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.outlineVariant,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        benefit.detail,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _StatusChip(isUnlocked: isUnlocked, isCurrent: isCurrent),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isUnlocked, required this.isCurrent});

  final bool isUnlocked;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: const Text(
          "You're here 📍",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }
    if (isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successTint,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: const Text(
          '✓ Unlocked',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: const Text(
        '🔒 Locked',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
