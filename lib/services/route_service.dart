import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/select_ward_screen.dart';
import '../screens/home_screen.dart';
import '../screens/admin_home_screen.dart';

class RouteService {
  /// Decides which screen a logged-in (or logged-out) user should see.
  /// Centralizing this in one place means Splash, Login, and Google
  /// Sign-In all make the exact same decision instead of repeating logic.
  static Future<Widget> resolveNextScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser == null) {
      return const LoginScreen();
    }

    final isGoogleUser = refreshedUser.providerData
        .any((info) => info.providerId == 'google.com');

    if (!refreshedUser.emailVerified && !isGoogleUser) {
      return const VerifyEmailScreen();
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(refreshedUser.uid)
        .get();

    final data = userDoc.data();
    final role = data?['role'] as String? ?? 'citizen';
    final wardId = data?['wardId'] as String?;

    if (role == 'citizen' && (wardId == null || wardId.isEmpty)) {
      return const SelectWardScreen();
    }

    if (role == 'admin') {
      return const AdminHomeScreen();
    }

    return const HomeScreen();
  }
}