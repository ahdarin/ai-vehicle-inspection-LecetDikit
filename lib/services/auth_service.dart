import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Pada v7, GoogleSignIn wajib menggunakan singleton (GoogleSignIn.instance)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Inisialisasi Google Sign-In (Langkah wajib di v7 sebelum memanggil metode lain)
  Future<void> init() async {
    await _googleSignIn.initialize(
      serverClientId: '273934132035-8kuvdrki16s5op6kht43oi6qghmkpru7.apps.googleusercontent.com',
    );
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

  // Login Google (Sesuai dokumentasi v7.2.0)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Menggunakan authenticate() untuk memanggil popup pemilihan akun
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Mengambil detail otentikasi (Di v7, ini bersifat synchronous, TANPA await)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Membungkus token ke dalam kredensial Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Meneruskan kredensial ke Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error Google Sign-In: $e");
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