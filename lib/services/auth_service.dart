import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Bundles the signed-in user together with whether their profile
/// still needs to be completed (name/phone/municipality/ward).
class GoogleSignInResult {
  final User user;
  final bool needsProfile;
  GoogleSignInResult({required this.user, required this.needsProfile});
}

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  /// Signs the user in with Google. Deliberately does NOT create a
  /// Firestore profile here - the calling screen decides what to do
  /// based on `needsProfile`, so first-time users can be sent to a
  /// proper "Complete Your Profile" screen instead of a silently
  /// half-filled account.
  static Future<GoogleSignInResult?> signInWithGoogle() async {
    await _ensureInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    final data = docSnapshot.data();

    final hasCompleteProfile = docSnapshot.exists &&
        data?['municipality'] != null &&
        data?['wardId'] != null;

    return GoogleSignInResult(user: user, needsProfile: !hasCompleteProfile);
  }
}