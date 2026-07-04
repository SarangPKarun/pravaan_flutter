import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../widgets/breathing_exercise_view.dart';
import '../widgets/distraction_view.dart';
import '../widgets/why_view.dart';

enum _SosView { menu, breathing, distraction, why }

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  _SosView _view = _SosView.menu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D38), AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _view == _SosView.menu ? _buildMenu(context) : _buildDetail(),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail() {
    return switch (_view) {
      _SosView.breathing =>
        BreathingExerciseView(onBack: () => setState(() => _view = _SosView.menu)),
      _SosView.distraction =>
        DistractionView(onBack: () => setState(() => _view = _SosView.menu)),
      _SosView.why => WhyView(onBack: () => setState(() => _view = _SosView.menu)),
      _SosView.menu => const SizedBox.shrink(),
    };
  }

  Widget _buildMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'You reached out.\nThat already matters.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.3,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        const Text(
          'Pick whatever feels right — this craving will pass.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Colors.white70,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xl),
        _SosOptionCard(
          emoji: '🌬️',
          title: '4-7-8 Breathing',
          subtitle: 'Calm your nervous system',
          onTap: () => setState(() => _view = _SosView.breathing),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(
              begin: 0.2,
              end: 0,
              delay: 150.ms,
              duration: 400.ms,
            ),
        const SizedBox(height: AppSpacing.md),
        _SosOptionCard(
          emoji: '🎯',
          title: 'Distraction',
          subtitle: 'Shift your focus for 5 minutes',
          onTap: () => setState(() => _view = _SosView.distraction),
        ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(
              begin: 0.2,
              end: 0,
              delay: 250.ms,
              duration: 400.ms,
            ),
        const SizedBox(height: AppSpacing.md),
        _SosOptionCard(
          emoji: '💭',
          title: 'Remember Your Why',
          subtitle: 'See what you\'re working toward',
          onTap: () => setState(() => _view = _SosView.why),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(
              begin: 0.2,
              end: 0,
              delay: 350.ms,
              duration: 400.ms,
            ),
      ],
    );
  }
}

class _SosOptionCard extends StatelessWidget {
  const _SosOptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
