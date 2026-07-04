import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/badges.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/badge_provider.dart';

class BadgeCelebrationScreen extends ConsumerStatefulWidget {
  const BadgeCelebrationScreen({super.key, required this.badge});
  final BadgeModel badge;

  @override
  ConsumerState<BadgeCelebrationScreen> createState() => _BadgeCelebrationScreenState();
}

class _BadgeCelebrationScreenState extends ConsumerState<BadgeCelebrationScreen> {
  final _captureKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  Timer? _autoDismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    ref.read(badgeAwardProvider.notifier).dismiss();
    if (mounted) context.pop();
  }

  Future<void> _shareAchievement() async {
    _autoDismissTimer?.cancel();
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3.0);
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final buttonBox =
            _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
        final origin = buttonBox != null
            ? buttonBox.localToGlobal(Offset.zero) & buttonBox.size
            : null;

        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(bytes, mimeType: 'image/png', name: '${widget.badge.id}_badge.png'),
            ],
            text: 'I just unlocked "${widget.badge.name}" on Pravaan! 🏅',
            sharePositionOrigin: origin,
          ),
        );
      }
    } catch (_) {
      // Sharing is best-effort — a failure here shouldn't break the celebration.
    } finally {
      if (mounted && !_dismissed) _scheduleAutoDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  'assets/lottie/confetti.json',
                  repeat: false,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RepaintBoundary(
                      key: _captureKey,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              badge.iconPath,
                              width: 144,
                              height: 144,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.emoji_events,
                                size: 112,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Badge unlocked!',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badge.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      key: _shareButtonKey,
                      width: double.infinity,
                      child: AppButton(
                        label: 'Share your achievement',
                        icon: const Icon(Icons.ios_share, size: 18, color: Colors.white),
                        onPressed: _shareAchievement,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
