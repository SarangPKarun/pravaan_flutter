import 'package:flutter/material.dart';

// TODO: Call supabase.auth.updateUser(UserAttributes(data: {'is_onboarded': true}))
// when the user completes onboarding to trigger the router redirect to /home.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('OnboardingScreen')),
    );
  }
}
