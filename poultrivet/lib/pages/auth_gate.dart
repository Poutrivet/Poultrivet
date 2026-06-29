import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'signup/signup_step2_page.dart';
import 'home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF19e16c)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();

        // Logged in — check if Firestore profile exists
        return FutureBuilder<bool>(
          future: authService.farmerProfileExists(user.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF19e16c)),
                ),
              );
            }

            final hasProfile = snap.data ?? false;
            if (hasProfile) return const HomePage();

            // Account exists in Firebase Auth but profile was never saved
            // (e.g. app crashed after account creation but before terms save).
            // Send them back to the terms page to finish up.
            return SignupStep2Page(
              fullName: '',
              district: '',
              phoneNumber:
                  user.email?.replaceAll('@poulvet.app', '') ?? '',
              password: '', // unused — account already created
            );
          },
        );
      },
    );
  }
}
