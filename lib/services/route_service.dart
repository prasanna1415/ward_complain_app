import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/complete_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/admin_home_screen.dart';

class RouteService {
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
    final municipality = data?['municipality'] as String?;
    final wardId = data?['wardId'] as String?;

    final profileIncomplete = municipality == null ||
        municipality.isEmpty ||
        wardId == null ||
        wardId.isEmpty;

    if (role == 'citizen' && profileIncomplete) {
      return const CompleteProfileScreen();
    }

    if (role == 'admin') {
      return const AdminHomeScreen();
    }

    return const HomeScreen();
  }
}