import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  // 1. Menyimpan hasil dari kamera AI (Dengan ID Custom dan Data Lengkap)
  Future<void> saveInspection({
    required String reportId, // ID custom (LD-...)
    required String vehicleName,
    required String plateNumber,
    required String status,
    required List<File> images, // Terima file asli
    required List<Map<String, dynamic>> findings, // Terima detail temuan
  }) async {
    try {
      // Ubah gambar pertama menjadi Base64 untuk thumbnail (agar tersimpan tanpa Firebase Storage)
      String base64Image = '';
      if (images.isNotEmpty) {
        final bytes = await images[0].readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // Gunakan reportId dari parameter sebagai Document ID
      await _db.collection('users').doc(_uid).collection('reports').doc(reportId).set({
        'id': reportId,
        'vehicleName': vehicleName,
        'plateNumber': plateNumber,
        'status': status, // Jangan di uppercase agar logic warna bekerja
        'timestamp': FieldValue.serverTimestamp(),
        'imageBase64': base64Image, // Simpan sebagai string Base64
        'findings': findings,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 2. Stream untuk daftar riwayat
  Stream<QuerySnapshot> streamInspections() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 3. Mengambil detail tunggal
  Future<DocumentSnapshot> getReportById(String reportId) {
    return _db.collection('users').doc(_uid).collection('reports').doc(reportId).get();
  }
}