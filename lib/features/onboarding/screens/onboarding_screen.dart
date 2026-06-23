import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';

// ── Habit catalogue ─────────────────────────────────────────────────────────
const _habits = [
  {'emoji': '🚬', 'label': 'Smoking',      'value': 'smoking',      'unit': 'cigarettes'},
  {'emoji': '🍺', 'label': 'Alcohol',      'value': 'alcohol',      'unit': 'drinks'},
  {'emoji': '💨', 'label': 'Vaping',       'value': 'vaping',       'unit': 'pods'},
  {'emoji': '🍬', 'label': 'Sugar',        'value': 'sugar',        'unit': 'servings'},
  {'emoji': '📱', 'label': 'Social Media', 'value': 'social_media', 'unit': 'sessions'},
  {'emoji': '☕', 'label': 'Coffee',       'value': 'coffee',       'unit': 'cups'},
  {'emoji': '🎰', 'label': 'Gambling',     'value': 'gambling',     'unit': 'bets'},
  {'emoji': '🎮', 'label': 'Gaming',       'value': 'gaming',       'unit': 'hours'},
];

String _unitFor(String? habitType) =>
    (_habits.firstWhere((h) => h['value'] == habitType,
            orElse: () => {'unit': 'units'})['unit']) ??
    'units';

String _emojiFor(String? habitType) =>
    (_habits.firstWhere((h) => h['value'] == habitType,
            orElse: () => {'emoji': '🔥'})['emoji']) ??
    '🔥';

// ── Screen ───────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _submitting = false;

  // Step-2 cost controller kept outside the build so it doesn't reset
  late final TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    final initCost = ref.read(onboardingProvider).unitCost;
    _costCtrl = TextEditingController(text: initCost.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ──────────────────────────────────────────────────
  void _next() {
    final data = ref.read(onboardingProvider);
    if (_page == 0 && data.habitType == null) {
      _snack('Please pick a habit first.');
      return;
    }
    if (_page == 1) {
      final cost = double.tryParse(_costCtrl.text.trim()) ?? 0;
      if (cost <= 0) {
        _snack('Enter a valid cost per unit.');
        return;
      }
      ref.read(onboardingProvider.notifier).setUnitCost(cost);
    }
    if (_page == 2) {
      _complete();
      return;
    }
    setState(() => _page++);
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _back() {
    if (_page == 0) return;
    setState(() => _page--);
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).setQuitDate(picked);
    }
  }

  Future<void> _complete() async {
    final data = ref.read(onboardingProvider);
    if (data.quitDate == null) {
      _snack('Please pick your quit date.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(onboardingProvider.notifier).complete();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _snack('Error saving: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(page: _page, onBack: _page > 0 ? _back : null),
            _ProgressBar(page: _page),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(data: data),
                  _Step2(data: data, costCtrl: _costCtrl),
                  _Step3(data: data, fmt: fmt, onPickDate: _pickDate),
                ],
              ),
            ),
            _BottomBar(
              page: _page,
              isLoading: _submitting,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, this.onBack});
  final int page;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            'Step ${page + 1} of 3',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── Progress bar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.page});
  final int page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (page + 1) / 3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (_, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {required this.page, required this.isLoading, required this.onNext});
  final int page;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: AppButton(
        label: page == 2 ? "Let's Go 🚀" : 'Continue',
        isLoading: isLoading,
        onPressed: onNext,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 1 — Habit selector grid
// ════════════════════════════════════════════════════════════════════════════
class _Step1 extends ConsumerWidget {
  const _Step1({required this.data});
  final OnboardingData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you\nquitting? 💪',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Choose the habit you want to break free from.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.builder(
              itemCount: _habits.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (_, i) {
                final h = _habits[i];
                final selected = data.habitType == h['value'];
                return _HabitTile(
                  emoji: h['emoji']!,
                  label: h['label']!,
                  value: h['value']!,
                  isSelected: selected,
                  onTap: () => ref
                      .read(onboardingProvider.notifier)
                      .setHabitType(h['value']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });
  final String emoji, label, value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 2 — Quantity + cost
// ════════════════════════════════════════════════════════════════════════════
class _Step2 extends ConsumerWidget {
  const _Step2({required this.data, required this.costCtrl});
  final OnboardingData data;
  final TextEditingController costCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);
    final unit = _unitFor(data.habitType);
    final emoji = _emojiFor(data.habitType);
    final dailySpend = data.dailyQty * (double.tryParse(costCtrl.text) ?? data.unitCost);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit reminder chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$emoji  ${data.habitType?.replaceAll('_', ' ') ?? ''}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Your daily habit', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('Help us calculate how much you can save.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // ── Daily qty card ─────────────────────────────────────────────
          _SectionCard(
            title: 'How many $unit per day?',
            child: _QtyStepperRow(
              qty: data.dailyQty,
              onDecrement: () => notifier.setDailyQty(data.dailyQty - 1),
              onIncrement: () => notifier.setDailyQty(data.dailyQty + 1),
            ),
          ),
          const SizedBox(height: 16),

          // ── Cost card ──────────────────────────────────────────────────
          _SectionCard(
            title: 'Cost per $unit (₹)',
            child: TextFormField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
              ),
              onChanged: (_) {
                final v = double.tryParse(costCtrl.text.trim()) ?? 0;
                notifier.setUnitCost(v);
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Auto-calculated summary ────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: dailySpend > 0
                ? _SpendSummary(dailySpend: dailySpend)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Text(title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _QtyStepperRow extends StatelessWidget {
  const _QtyStepperRow(
      {required this.qty, required this.onDecrement, required this.onIncrement});
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        Expanded(
          child: Center(
            child: Text(
              '$qty',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.successTint,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}

class _SpendSummary extends StatelessWidget {
  const _SpendSummary({required this.dailySpend});
  final double dailySpend;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D38), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Text('💸  You currently spend',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AmountCol(label: 'per day', amount: fmt.format(dailySpend)),
              _AmountCol(label: 'per month', amount: fmt.format(dailySpend * 30)),
              _AmountCol(label: 'per year', amount: fmt.format(dailySpend * 365)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountCol extends StatelessWidget {
  const _AmountCol({required this.label, required this.amount});
  final String label, amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(amount,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter')),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 3 — Quit date + projected savings
// ════════════════════════════════════════════════════════════════════════════
class _Step3 extends StatelessWidget {
  const _Step3(
      {required this.data,
      required this.fmt,
      required this.onPickDate});
  final OnboardingData data;
  final NumberFormat fmt;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final dateChosen = data.quitDate != null;
    final dateFmt = dateChosen
        ? DateFormat('EEEE, d MMMM yyyy').format(data.quitDate!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set your quit date 📅',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Pick the day you commit to breaking free.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // ── Date picker tile ─────────────────────────────────────────
          GestureDetector(
            onTap: onPickDate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: dateChosen ? AppColors.successTint : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: dateChosen
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: dateChosen ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateChosen ? 'Quit date' : 'Choose your quit date',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (dateChosen) ...[
                          const SizedBox(height: 2),
                          Text(dateFmt!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: dateChosen ? AppColors.primary : AppColors.outline,
                  ),
                ],
              ),
            ),
          ),

          // ── Projected savings ─────────────────────────────────────────
          if (dateChosen) ...[
            const SizedBox(height: 24),
            const Text(
              'Your projected savings',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _SavingsCard(data: data, fmt: fmt),
            const SizedBox(height: 16),
            _YearCard(data: data, fmt: fmt),
          ],
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.data, required this.fmt});
  final OnboardingData data;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final milestones = [
      ('1 week',   data.weeklySavings),
      ('1 month',  data.monthlySavings),
      ('6 months', data.sixMonthSavings),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < milestones.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              child: Row(
                children: [
                  Text(milestones[i].$1,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      )),
                  const Spacer(),
                  Text(fmt.format(milestones[i].$2),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      )),
                ],
              ),
            ),
            if (i < milestones.length - 1)
              const Divider(height: 1, color: AppColors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _YearCard extends StatelessWidget {
  const _YearCard({required this.data, required this.fmt});
  final OnboardingData data;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D38), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Text('In one year you could save',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(fmt.format(data.yearlySavings),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              )),
          const SizedBox(height: 4),
          const Text('That\'s real money back in your pocket. 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}
