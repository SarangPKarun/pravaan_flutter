import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/streak_display.dart';
import '../../streak/providers/streak_provider.dart';
import '../../wallet/models/goal_wallet_model.dart';
import '../../wallet/providers/wallet_list_provider.dart';
import '../providers/ai_dashboard_message_provider.dart';
import '../providers/dashboard_provider.dart';

/// Unit noun per habit type, mirroring the catalogue onboarding uses when a
/// habit is first created (see `onboarding_screen.dart`'s `_habitCatalogue`).
/// Kept as a separate lookup here since that catalogue is private to the
/// onboarding screen and dashboard data only carries the raw type string.
const _habitUnits = {
  'cigarette': 'cigarettes',
  'alcohol': 'drinks',
  'gutka': 'pieces',
  'junk_food': 'servings',
  'gambling': 'sessions',
  'custom': 'units',
};

String habitUnitLabel(String habitType) => _habitUnits[habitType] ?? 'units';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final aiMessageAsync = ref.watch(aiDashboardMessageProvider);
    final walletsAsync = ref.watch(userWalletsProvider);
    final isCheckedInToday = ref.watch(isCheckedInTodayProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar / greeting ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _GreetingHeader(data: data),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                // ── Motivational AI card ───────────────────────────────
                aiMessageAsync
                    .when(
                      loading: () => const _MotivationalCardShimmer(),
                      error: (_, _) =>
                          _MotivationalCard(message: data.motivationalMessage),
                      data: (message) => _MotivationalCard(message: message),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // ── Streak + Savings row ───────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StreakDisplay(streak: data.daysClean)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: walletsAsync
                          .when(
                            loading: () => const _SavingsCardLoading(),
                            error: (_, _) => const _SavingsCardEmpty(),
                            data: (wallets) => wallets.isEmpty
                                ? const _SavingsCardEmpty()
                                : _SavingsCard(wallet: wallets.first, fmt: fmt),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 400.ms),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Savings insight cards ───────────────────────────────
                _SavingsInsightsRow(
                  data: data,
                  fmt: fmt,
                  isCheckedInToday: isCheckedInToday,
                  totalSaved: walletsAsync.maybeWhen(
                    data: (wallets) =>
                        wallets.isEmpty ? null : wallets.first.currentBalance,
                    orElse: () => null,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Quick actions ──────────────────────────────────────
                _QuickActions()
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // ── Daily tip card ─────────────────────────────────────
                _DailyTipCard(data: data)
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Greeting header ───────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.data});
  final DashboardData data;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D38), AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting,',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.displayName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Streak badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(data.streakEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '${data.daysClean}d',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ── Motivational card ─────────────────────────────────────────────────────────
class _MotivationalCard extends StatelessWidget {
  const _MotivationalCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Motivation',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
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

// ── Motivational card shimmer placeholder ───────────────────────────────────
class _MotivationalCardShimmer extends StatelessWidget {
  const _MotivationalCardShimmer();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(90, 10),
                const SizedBox(height: 8),
                bar(double.infinity, 12),
                const SizedBox(height: 6),
                bar(160, 12),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        );
  }
}

// ── Savings card ──────────────────────────────────────────────────────────────
class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.wallet, required this.fmt});
  final GoalWalletModel wallet;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('💰', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 6),
              const Text(
                'Saved',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: wallet.currentBalance),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (_, value, _) => Text(
              fmt.format(value),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${wallet.daysRemaining} days to goal',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: wallet.progressPercent / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'toward "${wallet.goalName}"',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Savings card: loading state ─────────────────────────────────────────────
class _SavingsCardLoading extends StatelessWidget {
  const _SavingsCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Savings card: no goal wallet set up yet ─────────────────────────────────
class _SavingsCardEmpty extends StatelessWidget {
  const _SavingsCardEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💰', style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text(
            'Set up a savings goal to start tracking your progress.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Savings insight cards (horizontal scroll) ───────────────────────────────
class _SavingsInsightsRow extends StatelessWidget {
  const _SavingsInsightsRow({
    required this.data,
    required this.fmt,
    required this.isCheckedInToday,
    required this.totalSaved,
  });

  final DashboardData data;
  final NumberFormat fmt;
  final bool isCheckedInToday;

  /// Real wallet balance (same figure shown in the Savings card above), or
  /// null while it's loading/unavailable/no wallet exists yet.
  final double? totalSaved;

  // Illustrative reference prices (INR) for the "what could this buy" card —
  // no such pricing exists elsewhere in the app.
  static const _coffeePriceInr = 150;
  static const _bookPriceInr = 400;

  String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final savedToday = isCheckedInToday ? data.dailySavings : 0.0;
    final total = totalSaved ?? 0.0;
    final unitsAvoided = data.dailyQty * data.daysClean;
    final coffees = (total / _coffeePriceInr).floor();
    final books = (total / _bookPriceInr).floor();
    final countFmt = NumberFormat.decimalPattern('en_IN');

    final cards = [
      _StatCard(
        emoji: '📅',
        label: 'Saved Today',
        value: fmt.format(savedToday),
        color: AppColors.primary,
      ),
      _StatCard(
        emoji: '💰',
        label: 'Total Saved',
        value: fmt.format(total),
        color: const Color(0xFFFFA000),
      ),
      _StatCard(
        emoji: '🚫',
        label: '${_titleCase(habitUnitLabel(data.habitType))} Avoided',
        value: countFmt.format(unitsAvoided),
        color: const Color(0xFF6A1B9A),
      ),
      _StatCard(
        emoji: '🎁',
        label: 'Treat Yourself',
        value: '≈ $coffees ☕ or $books 📚',
        color: const Color(0xFF00838F),
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => cards[i]
            .animate()
            .fadeIn(delay: (400 + i * 80).ms, duration: 400.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              delay: (400 + i * 80).ms,
              duration: 400.ms,
            ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            emoji: '✅',
            label: 'Daily Check-In',
            subtitle: 'How are you feeling?',
            color: AppColors.primary,
            onTap: () => context.push('/checkin'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            emoji: '🆘',
            label: 'SOS',
            subtitle: 'Craving? Get help now',
            color: const Color(0xFFB71C1C),
            onTap: () => context.push('/sos'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            emoji: '👛',
            label: 'Wallet',
            subtitle: 'View your savings',
            color: const Color(0xFF1565C0),
            onTap: () => context.push('/wallet'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final String emoji, label, subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Daily tip card ────────────────────────────────────────────────────────────
class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({required this.data});
  final DashboardData data;

  static const _tips = [
    'Drink a glass of water when a craving hits — it only lasts 3–5 minutes.',
    'Take 5 deep breaths: inhale 4s, hold 7s, exhale 8s. Cravings fade.',
    'Call or text someone you trust when you feel the urge.',
    'Replace the habit with a short walk — even 5 minutes helps.',
    'Remind yourself WHY you started. Read it out loud.',
    'Chew sugar-free gum to keep your mouth busy.',
    'Celebrate small wins. Every clean day is a victory.',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().weekday % _tips.length];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Tip",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
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

