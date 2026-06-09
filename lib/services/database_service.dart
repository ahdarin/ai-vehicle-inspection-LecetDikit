import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan ID User yang sedang login
  String get _uid => _auth.currentUser?.uid ?? 'guest';

  // 1. Fungsi Menyimpan Hasil Inspeksi Baru
  Future<void> saveInspection({
    required String vehicleName,
    required String plateNumber,
    required String status,
    required String imageUrl,
    required List<String> findings,
  }) async {
    try {
      // Membuat ID unik otomatis untuk laporan
      String reportId = _db.collection('users').doc(_uid).collection('reports').doc().id;

      await _db.collection('users').doc(_uid).collection('reports').doc(reportId).set({
        'id': reportId,
        'vehicleName': vehicleName,
        'plateNumber': plateNumber,
        'status': status.toUpperCase(),
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'findings': findings,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 2. Stream untuk Mengambil Daftar Riwayat (Real-time)
  Stream<QuerySnapshot> streamInspections() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 3. Fungsi Mendapatkan Detail Satu Laporan Berdasarkan ID
  Future<DocumentSnapshot> getReportById(String reportId) {
    return _db.collection('users').doc(_uid).collection('reports').doc(reportId).get();
  }
}