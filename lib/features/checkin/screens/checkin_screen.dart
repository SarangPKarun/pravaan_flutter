import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/streak_display.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../streak/providers/streak_provider.dart';
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
  bool? _isClean;
  int _moodIndex = 2;
  int _cravingIntensity = 3;
  String? _cravingTrigger;
  TimeOfDay _cravingTime = TimeOfDay.now();
  int _previousStreak = 0; // streak captured before slip resets it
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
    if (_isClean == false) {
      _previousStreak = ref.read(streakProvider).currentStreak;
    }
    final h = _cravingTime.hour.toString().padLeft(2, '0');
    final m = _cravingTime.minute.toString().padLeft(2, '0');
    await ref.read(checkinProvider.notifier).submitCheckin(
          isClean: _isClean!,
          mood: _moodIndex + 1,
          cravingIntensity: _isClean! ? null : _cravingIntensity,
          cravingTrigger: _isClean! ? null : _cravingTrigger,
          cravingTime: _isClean! ? null : '$h:$m',
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
        // Slip: user taps 'Restart my streak' manually — no auto-pop here.
        if (_isClean == true) {
          final router = GoRouter.of(context);
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (mounted) {
              ref.read(checkinProvider.notifier).reset();
              router.pop();
            }
          });
        }
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
          ? (_isClean == false
              ? _RelapseRecoveryView(
                  previousStreak: _previousStreak,
                  ctrl: _successCtrl,
                )
              : _SuccessView(ctrl: _successCtrl))
          : _FormView(
              streak: ref.watch(currentStreakProvider),
              isClean: _isClean,
              moodIndex: _moodIndex,
              cravingIntensity: _cravingIntensity,
              cravingTrigger: _cravingTrigger,
              cravingTime: _cravingTime,
              noteCtrl: _noteCtrl,
              isSubmitting: isSubmitting,
              onSelectClean: (v) => setState(() => _isClean = v),
              onMoodChange: (i) => setState(() => _moodIndex = i),
              onCravingIntensityChange: (v) =>
                  setState(() => _cravingIntensity = v),
              onCravingTriggerChange: (v) =>
                  setState(() => _cravingTrigger = v),
              onCravingTimeChange: (v) =>
                  setState(() => _cravingTime = v),
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
    required this.streak,
    required this.isClean,
    required this.moodIndex,
    required this.cravingIntensity,
    required this.cravingTrigger,
    required this.cravingTime,
    required this.noteCtrl,
    required this.isSubmitting,
    required this.onSelectClean,
    required this.onMoodChange,
    required this.onCravingIntensityChange,
    required this.onCravingTriggerChange,
    required this.onCravingTimeChange,
    required this.onSubmit,
  });

  final int streak;
  final bool? isClean;
  final int moodIndex;
  final int cravingIntensity;
  final String? cravingTrigger;
  final TimeOfDay cravingTime;
  final TextEditingController noteCtrl;
  final bool isSubmitting;
  final ValueChanged<bool> onSelectClean;
  final ValueChanged<int> onMoodChange;
  final ValueChanged<int> onCravingIntensityChange;
  final ValueChanged<String?> onCravingTriggerChange;
  final ValueChanged<TimeOfDay> onCravingTimeChange;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Streak reminder ───────────────────────────────────────────
          StreakDisplay(streak: streak)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

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
                    child: _CravingLog(
                      controller: noteCtrl,
                      intensity: cravingIntensity,
                      onIntensityChange: onCravingIntensityChange,
                      trigger: cravingTrigger,
                      onTriggerChange: onCravingTriggerChange,
                      cravingTime: cravingTime,
                      onTimeChange: onCravingTimeChange,
                    )
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
            label: 'I\nSlipped',
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

const _intensityLabels = {
  1: 'Mild 🟡',
  2: 'Low 🟢',
  3: 'Moderate 🟠',
  4: 'Strong 🔴',
  5: 'Overwhelming 🔴',
};

const _triggers = [
  ('stress',  '🧠', 'Stress'),
  ('boredom', '🥱', 'Boredom'),
  ('social',  '👥', 'Social'),
  ('other',   '🤔', 'Other'),
];

class _CravingLog extends StatelessWidget {
  const _CravingLog({
    required this.controller,
    required this.intensity,
    required this.onIntensityChange,
    required this.trigger,
    required this.onTriggerChange,
    required this.cravingTime,
    required this.onTimeChange,
  });

  final TextEditingController controller;
  final int intensity;
  final ValueChanged<int> onIntensityChange;
  final String? trigger;
  final ValueChanged<String?> onTriggerChange;
  final TimeOfDay cravingTime;
  final ValueChanged<TimeOfDay> onTimeChange;

  static const _slipColor = Color(0xFFE65100);

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: cravingTime,
    );
    if (picked != null) onTimeChange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final intensityLabel = _intensityLabels[intensity] ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _slipColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trigger chips ────────────────────────────────────────────
          const Row(
            children: [
              Text('💥', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'What triggered it?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _slipColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _triggers.map((t) {
              final (value, emoji, label) = t;
              final selected = trigger == value;
              return GestureDetector(
                onTap: () => onTriggerChange(selected ? null : value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _slipColor : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: selected
                          ? _slipColor
                          : _slipColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$emoji $label',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _slipColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Intensity slider (1–5) ───────────────────────────────────
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'How intense was the craving?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _slipColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _slipColor,
                    inactiveTrackColor: _slipColor.withValues(alpha: 0.2),
                    thumbColor: _slipColor,
                    overlayColor: _slipColor.withValues(alpha: 0.12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: intensity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) => onIntensityChange(v.round()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '$intensity',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _slipColor,
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                intensityLabel,
                key: ValueKey(intensityLabel),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Time of day ──────────────────────────────────────────────
          Row(
            children: [
              const Text('⏰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'When did it happen?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _slipColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _pickTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: _slipColor),
                  ),
                  child: Text(
                    cravingTime.format(context),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _slipColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Note field ───────────────────────────────────────────────
          const Row(
            children: [
              Text('📝', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Anything else?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _slipColor,
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
              hintText: 'Any extra context…',
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
  const _SuccessView({required this.ctrl});
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    const emoji = '🎉';
    const headline = 'Another clean day!';
    const body = 'You\'re building unstoppable momentum.\nKeep it up!';
    const bg = AppColors.primary;

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

// ════════════════════════════════════════════════════════════════════════════
// Relapse recovery view
// ════════════════════════════════════════════════════════════════════════════
class _RelapseRecoveryView extends ConsumerWidget {
  const _RelapseRecoveryView({
    required this.previousStreak,
    required this.ctrl,
  });

  final int previousStreak;
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final moneySaved =
        (data.totalCleanDays * data.dailySavings).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D38), Color(0xFF2E4A3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💚', style: TextStyle(fontSize: 64))
                  .animate(controller: ctrl)
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 32),

              const Text(
                'Everyone slips.',
                style: TextStyle(
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
                  .slideY(
                      begin: 0.2, end: 0, delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 10),

              const Text(
                'What matters is restarting.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(controller: ctrl)
                  .fadeIn(delay: 450.ms, duration: 400.ms),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '$previousStreak',
                      label: 'days completed',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      value: '₹$moneySaved',
                      label: 'still saved',
                    ),
                  ),
                ],
              )
                  .animate(controller: ctrl)
                  .fadeIn(delay: 600.ms, duration: 400.ms)
                  .slideY(
                      begin: 0.15, end: 0, delay: 600.ms, duration: 400.ms),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  onPressed: () {
                    ref.read(checkinProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Restart my streak →',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
                  .animate(controller: ctrl)
                  .fadeIn(delay: 800.ms, duration: 400.ms)
                  .slideY(
                      begin: 0.1, end: 0, delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
