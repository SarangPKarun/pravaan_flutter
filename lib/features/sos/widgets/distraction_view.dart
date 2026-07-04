import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class DistractionView extends StatefulWidget {
  const DistractionView({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<DistractionView> createState() => _DistractionViewState();
}

class _DistractionViewState extends State<DistractionView> {
  static const _totalSeconds = 5 * 60;
  static const _prompts = [
    'Name 5 things you can see right now.',
    'Step outside for a minute of fresh air.',
    'Do 10 jumping jacks or push-ups.',
    'Text a friend and tell them how you\'re feeling.',
    'Splash cold water on your face.',
    'Tidy up one small corner of the room.',
    'Write down what triggered this craving.',
  ];

  late final String _prompt = _prompts[Random().nextInt(_prompts.length)];
  int _secondsLeft = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final done = _secondsLeft == 0;

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
        Text(
          _formattedTime,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Text(
            done ? 'Nice work — how do you feel?' : _prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: TextButton(
            onPressed: widget.onBack,
            child: Text(
              done ? 'Back to options' : 'Skip',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
