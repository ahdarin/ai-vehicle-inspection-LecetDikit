import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  // 1. Simpan Data Inspeksi (Sinkronisasi Tipe Data 100%)
  Future<void> saveInspection({
    required String reportId,
    required String vehicleName,
    required String plateNumber,
    required String status,
    required List<File> images,
    required List<Map<String, dynamic>> findings, // Menyimpan koordinat AI
  }) async {
    try {
      // Simpan file gambar secara lokal di dalam folder aplikasi
      final directory = await getApplicationDocumentsDirectory();
      List<String> localImagePaths = [];
      
      for (int i = 0; i < images.length; i++) {
        final String ext = images[i].path.split('.').last;
        final String fileName = '${reportId}_$i.$ext';
        final File localImage = await images[i].copy('${directory.path}/$fileName');
        localImagePaths.add(localImage.path); // Simpan path-nya
      }

      // Simpan data terstruktur ke Firestore
      await _db.collection('users').doc(_uid).collection('reports').doc(reportId).set({
        'id': reportId,
        'vehicleName': vehicleName,
        'plateNumber': plateNumber,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'localImagePaths': localImagePaths,
        'findings': findings,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 2. Stream Daftar Riwayat
  Stream<QuerySnapshot> streamInspections() {
    return _db.collection('users').doc(_uid).collection('reports')
        .orderBy('timestamp', descending: true).snapshots();
  }

  // 3. Mengambil Detail Riwayat
  Future<DocumentSnapshot> getReportById(String reportId) {
    return _db.collection('users').doc(_uid).collection('reports').doc(reportId).get();
  }

  // 4. Hapus Riwayat + Hapus Gambar Lokal
  Future<void> deleteInspection(String reportId) async {
    try {
      DocumentSnapshot doc = await getReportById(reportId);
      if (doc.exists) {
        List<dynamic> paths = doc.get('localImagePaths') ?? [];
        for (String path in paths) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      }
      await _db.collection('users').doc(_uid).collection('reports').doc(reportId).delete();
    } catch (e) {
      rethrow;
    }
  }
}