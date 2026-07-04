import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';

enum _BreathPhase { inhale, hold, exhale }

extension on _BreathPhase {
  String get label => switch (this) {
        _BreathPhase.inhale => 'Breathe In',
        _BreathPhase.hold => 'Hold',
        _BreathPhase.exhale => 'Breathe Out',
      };

  int get seconds => switch (this) {
        _BreathPhase.inhale => 4,
        _BreathPhase.hold => 7,
        _BreathPhase.exhale => 8,
      };
}

class BreathingExerciseView extends StatefulWidget {
  const BreathingExerciseView({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<BreathingExerciseView> createState() => _BreathingExerciseViewState();
}

class _BreathingExerciseViewState extends State<BreathingExerciseView>
    with SingleTickerProviderStateMixin {
  static const _totalLoops = 4;

  late final AnimationController _controller;
  final _audioPlayer = AudioPlayer();
  _BreathPhase _phase = _BreathPhase.inhale;
  int _secondsLeft = _BreathPhase.inhale.seconds;
  bool _active = true;
  bool _done = false;
  Timer? _secondTicker;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, lowerBound: 0.4, upperBound: 1.0);
    _runCycle();
  }

  Future<void> _runCycle() async {
    for (var loop = 0; loop < _totalLoops; loop++) {
      if (!_active || !mounted) return;
      await _enterPhase(_BreathPhase.inhale);
      if (!_active || !mounted) return;
      await _enterPhase(_BreathPhase.hold);
      if (!_active || !mounted) return;
      await _enterPhase(_BreathPhase.exhale);
    }
    if (_active && mounted) setState(() => _done = true);
  }

  Future<void> _enterPhase(_BreathPhase phase) async {
    setState(() {
      _phase = phase;
      _secondsLeft = phase.seconds;
    });
    unawaited(_playCue());

    _secondTicker?.cancel();
    _secondTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, phase.seconds));
    });

    _controller.duration = Duration(seconds: phase.seconds);
    switch (phase) {
      case _BreathPhase.inhale:
        await _controller.forward(from: _controller.value);
      case _BreathPhase.hold:
        await Future.delayed(Duration(seconds: phase.seconds));
      case _BreathPhase.exhale:
        await _controller.reverse(from: _controller.value);
    }
  }

  /// Soft cue marking a phase change. Best-effort — a missing/failed audio
  /// asset shouldn't interrupt the breathing exercise itself.
  Future<void> _playCue() async {
    try {
      await _audioPlayer.play(AssetSource('audio/breath_cue.wav'), volume: 0.5);
    } catch (e) {
      debugPrint('BreathingExerciseView: failed to play cue — $e');
    }
  }

  @override
  void dispose() {
    _active = false;
    _secondTicker?.cancel();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
        ),
        const Spacer(),
        if (_done) _buildReflection() else _buildBreathing(),
        const Spacer(),
        if (!_done)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Text(
              'The 4-7-8 technique calms your nervous system.\n4 rounds, then check back in with yourself.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBreathing() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
            width: 220 * _controller.value,
            height: 220 * _controller.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _phase.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$_secondsLeft',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildReflection() {
    return Column(
      children: [
        const Text(
          'How do you feel?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ReflectionButton(emoji: '😌', label: 'Better', onTap: widget.onBack),
            const SizedBox(width: AppSpacing.xl),
            _ReflectionButton(emoji: '😤', label: 'Still tough', onTap: widget.onBack),
          ],
        ),
      ],
    );
  }
}

class _ReflectionButton extends StatelessWidget {
  const _ReflectionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
