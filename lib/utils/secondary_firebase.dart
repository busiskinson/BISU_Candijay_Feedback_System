import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

/// A second Firebase App instance used only for creating new staff
/// accounts from the Admin panel, so doing so doesn't sign the
/// currently logged-in Admin out of their own session.
class SecondaryFirebase {
  static FirebaseApp? _app;

  static Future<FirebaseApp> _getApp() async {
    if (_app != null) return _app!;
    _app = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return _app!;
  }

  /// Creates a new account and returns its UID, without affecting
  /// the primary app's currently logged-in user.
  static Future<String> createStaffAccount({
    required String email,
    required String password,
  }) async {
    final app = await _getApp();
    final auth = FirebaseAuth.instanceFor(app: app);

    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Sign out of the secondary app immediately — we only needed it
    // to create the account; the Admin's own session is untouched.
    await auth.signOut();

    return uid;
  }
}