import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';

/// Self-contained gradient card showing a streak count, an animated 🔥,
/// and a "days clean" subtitle. Pass the current streak as [streak].
///
/// Apply entrance animations at the call site:
///   StreakDisplay(streak: n).animate().fadeIn().slideY(begin: 0.15)
class StreakDisplay extends StatelessWidget {
  const StreakDisplay({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D38), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: animated flame + label
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 0.88,
                    end: 1.12,
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(width: 6),
              const Text(
                'Streak',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Count-up number
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: streak.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Text(
              value.round().toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'days clean',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
