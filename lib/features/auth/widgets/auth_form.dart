import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';

// ---------------------------------------------------------------------------
// Google "G" logo via CustomPainter — no extra package required
// ---------------------------------------------------------------------------
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // White background
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    // Draw four colored arcs (red, green, yellow, blue)
    final sw = w * 0.18;
    final outerR = r - sw / 2;

    void arc(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    const pi = 3.14159265;
    arc(-pi / 2, pi * 0.95, const Color(0xFF4285F4)); // blue — top‑left
    arc(-pi / 2 + pi * 0.95, pi * 0.5, const Color(0xFF34A853)); // green
    arc(-pi / 2 + pi * 1.45, pi * 0.55, const Color(0xFFFBBC05)); // yellow
    arc(-pi / 2 + pi * 2.0, pi * 0.5, const Color(0xFFEA4335)); // red

    // White right-side cutout to create the "G" gap
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - sw, r, sw * 2),
      Paint()..color = Colors.white,
    );

    // Blue horizontal bar (right arm of G)
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - sw * 0.4, outerR, sw * 0.8),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Auth Form
// ---------------------------------------------------------------------------

enum _AuthMode { signIn, signUp }

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.isLoading,
    required this.onEmailSignIn,
    required this.onEmailSignUp,
    required this.onGoogleSignIn,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final VoidCallback onEmailSignIn;
  final VoidCallback onEmailSignUp;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onForgotPassword;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm>
    with SingleTickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn ? _AuthMode.signUp : _AuthMode.signIn;
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == _AuthMode.signIn;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Email ──────────────────────────────────────────────────────
            TextFormField(
              controller: widget.emailController,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Password ───────────────────────────────────────────────────
            TextFormField(
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),

            // ── Forgot password (sign-in only) ─────────────────────────────
            if (isSignIn) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.isLoading ? null : widget.onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 14),

            // ── Primary CTA ────────────────────────────────────────────────
            AppButton(
              label: isSignIn ? 'Sign In' : 'Create Account',
              isLoading: widget.isLoading,
              onPressed: () {
                if (widget.formKey.currentState!.validate()) {
                  isSignIn ? widget.onEmailSignIn() : widget.onEmailSignUp();
                }
              },
            ),
            const SizedBox(height: 16),

            // ── Divider ────────────────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                    child: Divider(color: AppColors.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(
                    child: Divider(color: AppColors.outlineVariant)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Google Sign-In ─────────────────────────────────────────────
            AppButton(
              label: 'Continue with Google',
              variant: AppButtonVariant.outline,
              icon: const _GoogleLogo(size: 18),
              isLoading: false,
              onPressed: widget.isLoading ? null : widget.onGoogleSignIn,
            ),
            const SizedBox(height: 24),

            // ── Mode toggle ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSignIn
                      ? "Don't have an account? "
                      : 'Already have an account? ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                GestureDetector(
                  onTap: widget.isLoading ? null : _toggleMode,
                  child: Text(
                    isSignIn ? 'Sign Up' : 'Sign In',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
