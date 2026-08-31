import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _checkTimer;
  Timer? _cooldownTimer;
  bool _isSending = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Automatically check every 3 seconds whether the user has clicked the link.
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      _checkTimer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Check your inbox.')),
      );
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send email. Please try again shortly.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 30;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  Future<void> _logout() async {
    _checkTimer?.cancel();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Check your inbox',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification link to\n$email\n\nTap the link to activate your account. This screen will continue automatically once verified.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSending || _resendCooldown > 0 ? null : _resendEmail,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : 'Resend Email',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _logout,
              child: const Text('Use a different account'),
            ),
          ],
        ),
      ),
    );
  }
}