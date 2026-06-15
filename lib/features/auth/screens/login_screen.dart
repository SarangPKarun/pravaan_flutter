import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_form.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authNotifierProvider, (_, next) {
      if (next is AsyncError) {
        final msg = next.error is AuthException
            ? (next.error as AuthException).message
            : next.error.toString();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AuthForm(
          emailController: _emailController,
          passwordController: _passwordController,
          formKey: _formKey,
          isLoading: isLoading,
          onEmailSignIn: () {
            if (_formKey.currentState!.validate()) {
              ref.read(authNotifierProvider.notifier).signInWithEmailPassword(
                    _emailController.text.trim(),
                    _passwordController.text,
                  );
            }
          },
          onGoogleSignIn: () =>
              ref.read(authNotifierProvider.notifier).signInWithGoogle(),
        ),
      ),
    );
  }
}
