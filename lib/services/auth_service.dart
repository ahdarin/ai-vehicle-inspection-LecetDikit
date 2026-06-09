import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In v7
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Inisialisasi Google Sign In
  Future<void> init() async {
    await _googleSignIn.initialize();
  }

  // User saat ini
  User? get currentUser => _auth.currentUser;

  // Stream auth realtime
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login Email/Password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register Email/Password
  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Login Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Munculkan popup pilih akun Google
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      // Ambil token
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Buat credential Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Login ke Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Login Anonymous
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}