import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  /// Signs the user in with Google, creates their Firestore profile
  /// only if this is their first time signing in.
  /// Returns the signed-in User, or null if the user cancelled.
  static Future<User?> signInWithGoogle() async {
    await _ensureInitialized();

    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final userDoc =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // First time signing in with this Google account - create profile.
        await userDoc.set({
          'name': user.displayName ?? 'Ward User',
          'email': user.email ?? '',
          'role': 'citizen',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return user;
  }
}