import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lecetdikit/services/database_service.dart';
import 'package:intl/intl.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String reportId;
  const HistoryDetailScreen({super.key, required this.reportId});

  Color _getStatusColor(String status) {
    if (status == 'Sangat Baik') return Colors.green;
    if (status == 'Butuh Perbaikan Segera') return Colors.red;
    if (status == 'Minor / Perhatian') return Colors.orange;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LecetDikit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: dbService.getReportById(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Laporan tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String vehicleName = data['vehicleName'] ?? '';
          final String plateNumber = data['plateNumber'] ?? '';
          final String statusUmum = data['status'] ?? 'Sangat Baik';
          final String base64Image = data['imageBase64'] ?? '';
          final List<dynamic> findings = data['findings'] ?? [];
          final bool isSafe = findings.isEmpty;
          
          String formattedDate = '-';
          if (data['timestamp'] != null) {
            final now = (data['timestamp'] as Timestamp).toDate();
            formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          }

          final statusColor = _getStatusColor(statusUmum);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(reportId, style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                  Text(formattedDate, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Hasil Analisis', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              if (vehicleName.isNotEmpty && vehicleName != 'Mobil Tidak Dikenal' || plateNumber.isNotEmpty && plateNumber != '-')
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('$vehicleName • $plateNumber', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant))),
              
              const SizedBox(height: 24),

              // Render Gambar dari Base64
              if (base64Image.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                      child: Text('FOTO 1', style: TextStyle(color: colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))),
                        child: Image.memory(base64Decode(base64Image), width: double.infinity, fit: BoxFit.fitWidth),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL KERUSAKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                          const SizedBox(height: 8),
                          Text('${findings.length} Titik', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface))
                        ],
                      ),
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STATUS UMUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                          const SizedBox(height: 12),
                          Text(statusUmum, style: TextStyle(fontSize: 18, height: 1.1, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    )
                  )
                ],
              ),

              const SizedBox(height: 32),
              Text('Detail Temuan AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 16),
              
              if (isSafe)
                const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Kondisi eksterior sangat baik.')))
              else
                ...findings.map((res) {
                  // Ekstrak Map yang kita simpan tadi
                  Map<String, dynamic> findingMap = res as Map<String, dynamic>;
                  String damageName = findingMap['damageName'] ?? 'Tidak Dikenal';
                  int photoIndex = findingMap['photoIndex'] ?? 1;
                  double confidence = findingMap['confidence'] ?? 0.0;
                  bool isHeavy = findingMap['isHeavy'] ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isHeavy ? colorScheme.error.withOpacity(0.5) : colorScheme.outlineVariant.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: isHeavy ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest, 
                          child: Icon(isHeavy ? Icons.car_crash : Icons.format_paint, color: isHeavy ? colorScheme.error : colorScheme.onSurfaceVariant)
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(damageName.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isHeavy ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(isHeavy ? 'BERAT' : 'RINGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHeavy ? colorScheme.error : colorScheme.onSurfaceVariant)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Kerusakan terdeteksi pada Foto $photoIndex.', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              Text('AI Match: ${(confidence * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.secondary))
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}