import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/checkin_provider.dart';

// Mood labels indexed 0-4 (mood values 1-5)
const _moodEmojis  = ['😔', '😕', '😐', '🙂', '😊'];
const _moodLabels  = ['Rough', 'Hard', 'Okay', 'Good', 'Great'];

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with SingleTickerProviderStateMixin {
  bool? _isClean;         // null = not yet chosen
  int _moodIndex = 2;     // 0-4 → maps to mood 1-5
  final _noteCtrl = TextEditingController();

  late final AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isClean == null) {
      _snack('Please choose Stayed Clean or Had a Slip first.');
      return;
    }
    await ref.read(checkinProvider.notifier).submitCheckin(
          isClean: _isClean!,
          mood: _moodIndex + 1,
          note: _noteCtrl.text,
        );
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
    // Listen for state changes
    ref.listen<CheckinState>(checkinProvider, (_, next) {
      if (next.status == CheckinStatus.success) {
        _successCtrl.forward(from: 0);
        // Capture router before the delay to avoid using BuildContext async
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            ref.read(checkinProvider.notifier).reset();
            router.pop();
          }
        });
      }
      if (next.status == CheckinStatus.error) {
        _snack(next.errorMessage ?? 'Failed to save. Try again.');
      }
    });

    final checkinState = ref.watch(checkinProvider);
    final isSubmitting = checkinState.status == CheckinStatus.submitting;
    final isSuccess    = checkinState.status == CheckinStatus.success;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Check-In'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: isSuccess
          ? _SuccessView(isClean: _isClean ?? true, ctrl: _successCtrl)
          : _FormView(
              isClean: _isClean,
              moodIndex: _moodIndex,
              noteCtrl: _noteCtrl,
              isSubmitting: isSubmitting,
              onSelectClean: (v) => setState(() => _isClean = v),
              onMoodChange: (i) => setState(() => _moodIndex = i),
              onSubmit: _submit,
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Form view
// ════════════════════════════════════════════════════════════════════════════
class _FormView extends StatelessWidget {
  const _FormView({
    required this.isClean,
    required this.moodIndex,
    required this.noteCtrl,
    required this.isSubmitting,
    required this.onSelectClean,
    required this.onMoodChange,
    required this.onSubmit,
  });

  final bool? isClean;
  final int moodIndex;
  final TextEditingController noteCtrl;
  final bool isSubmitting;
  final ValueChanged<bool> onSelectClean;
  final ValueChanged<int> onMoodChange;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section title ────────────────────────────────────────────
          Text('How did today go?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Be honest — every check-in counts.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),

          // ── Hero choice buttons ───────────────────────────────────────
          _HeroChoiceRow(
            selected: isClean,
            onSelect: onSelectClean,
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 28),

          // ── Mood selector ─────────────────────────────────────────────
          _MoodSelector(
            moodIndex: moodIndex,
            onChanged: onMoodChange,
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 400.ms),

          // ── Craving log (conditional) ─────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: isClean == false
                ? Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _CravingLog(controller: noteCtrl)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0, duration: 300.ms),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),

          // ── Submit ────────────────────────────────────────────────────
          AppButton(
            label: 'Save Check-In',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Hero choice row ───────────────────────────────────────────────────────────
class _HeroChoiceRow extends StatelessWidget {
  const _HeroChoiceRow({required this.selected, required this.onSelect});
  final bool? selected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceCard(
            emoji: '✅',
            label: 'Stayed\nClean',
            active: selected == true,
            activeColor: AppColors.primary,
            onTap: () => onSelect(true),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ChoiceCard(
            emoji: '😔',
            label: 'Had a\nSlip',
            active: selected == false,
            activeColor: const Color(0xFFE65100),
            onTap: () => onSelect(false),
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.emoji,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String emoji, label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 140,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: active ? activeColor : AppColors.outlineVariant,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mood selector ─────────────────────────────────────────────────────────────
class _MoodSelector extends StatelessWidget {
  const _MoodSelector({required this.moodIndex, required this.onChanged});
  final int moodIndex;
  final ValueChanged<int> onChanged;

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
          const Text(
            'How are you feeling?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final selected = moodIndex == i;
              return GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Text(
                    _moodEmojis[i],
                    style: TextStyle(
                      fontSize: selected ? 30 : 24,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _moodLabels[moodIndex],
                key: ValueKey(moodIndex),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Craving log ───────────────────────────────────────────────────────────────
class _CravingLog extends StatelessWidget {
  const _CravingLog({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📝', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'What happened?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Writing it down helps you spot triggers. No judgement here.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'e.g. stress at work, social setting, boredom…',
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Success view
// ════════════════════════════════════════════════════════════════════════════
class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.isClean, required this.ctrl});
  final bool isClean;
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    final emoji   = isClean ? '🎉' : '💚';
    final headline = isClean ? 'Another clean day!' : 'Thanks for being honest.';
    final body = isClean
        ? 'You\'re building unstoppable momentum.\nKeep it up!'
        : 'Slips happen. What matters is you\'re\nstill here and trying. That\'s strength.';
    final bg = isClean ? AppColors.primary : const Color(0xFF2E4A3F);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF004D38), bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated emoji
            Text(emoji, style: const TextStyle(fontSize: 72))
                .animate(controller: ctrl)
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 28),

            Text(
              headline,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate(controller: ctrl)
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 16),

            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Colors.white70,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
                .animate(controller: ctrl)
                .fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 48),

            // Returning indicator
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            )
                .animate(controller: ctrl)
                .fadeIn(delay: 800.ms, duration: 400.ms),

            const SizedBox(height: 12),

            Text(
              'Returning to home…',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            )
                .animate(controller: ctrl)
                .fadeIn(delay: 800.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
