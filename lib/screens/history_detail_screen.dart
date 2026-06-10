import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lecetdikit/services/database_service.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/services/pdf_service.dart';
import 'package:lecetdikit/widgets/bounding_box_painter.dart';
import 'package:intl/intl.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String reportId;
  const HistoryDetailScreen({super.key, required this.reportId});

  bool _isHeavyDamage(DetectionResult res, AiService aiService) {
    String damageType = aiService.classNames[res.classIndex];
    if (damageType == 'Kaca Pecah' || damageType == 'Lampu Pecah' || damageType == 'Ban Kempes') return true; 
    double area = res.w * res.h;
    double maxLength = res.w > res.h ? res.w : res.h;
    if (damageType == 'Goresan' && maxLength > 0.40) return true;
    if (damageType == 'Retak' && maxLength > 0.25) return true;
    if (damageType == 'Penyok' && area > 0.15) return true;
    return false;
  }

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
    final AiService aiService = AiService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LecetDikit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: dbService.getReportById(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Laporan tidak ditemukan.'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String vehicleName = data['vehicleName'] ?? '';
          final String plateNumber = data['plateNumber'] ?? '';
          final String statusUmum = data['status'] ?? 'Sangat Baik';
          
          // Mengambil gambar dari memory lokal
          final List<dynamic> localPaths = data['localImagePaths'] ?? [];
          final List<File> images = localPaths.map((path) => File(path.toString())).toList();
          
          // Membangun ulang tipe data DetectionResult agar bounding box bisa digambar lagi!
          final List<dynamic> rawFindings = data['findings'] ?? [];
          final List<DetectionResult> results = rawFindings.map((f) {
            return DetectionResult(
              classIndex: f['classIndex'] ?? 0,
              confidence: f['confidence'] ?? 0.0,
              photoIndex: f['photoIndex'] ?? 1,
              x: f['x'] ?? 0.0,
              y: f['y'] ?? 0.0,
              w: f['w'] ?? 0.0,
              h: f['h'] ?? 0.0,
            );
          }).toList();

          final bool isSafe = results.isEmpty;
          final statusColor = _getStatusColor(statusUmum);

          String formattedDate = '-';
          if (data['timestamp'] != null) {
            final now = (data['timestamp'] as Timestamp).toDate();
            formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          }

          // KODE DI BAWAH INI KLONING 100% REPORT SCREEN
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
              if (vehicleName.isNotEmpty || plateNumber.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('$vehicleName • $plateNumber', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant))),
              
              const SizedBox(height: 24),

              ...List.generate(images.length, (index) {
                int currentPhotoIndex = index + 1;
                var photoResults = results.where((r) => r.photoIndex == currentPhotoIndex).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                      child: Text('FOTO $currentPhotoIndex', style: TextStyle(color: colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))),
                        child: Stack(
                          children: [
                            Image.file(images[index], width: double.infinity, fit: BoxFit.fitWidth, 
                              errorBuilder: (context, error, stackTrace) => Container(height: 200, color: colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)))
                            ),
                            // Bounding Box kini berfungsi di Riwayat!
                            Positioned.fill(child: CustomPaint(painter: BoundingBoxPainter(photoResults, aiService.classNames))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

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
                          Text('${results.length} Titik', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface))
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
                ...results.map((res) {
                  String damageName = aiService.classNames[res.classIndex];
                  bool isHeavy = _isHeavyDamage(res, aiService); 
                  
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
                              Text('Kerusakan terdeteksi pada Foto ${res.photoIndex}.', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              Text('AI Match: ${(res.confidence * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.secondary))
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyiapkan dokumen PDF...')));
                    await PdfService.generateAndPrintReport(
                      images: images,             // Menggunakan variabel list images lokal
                      results: results,           // Menggunakan variabel list results lokal
                      carModel: vehicleName,      // Di database namanya vehicleName
                      plateNumber: plateNumber,   // Di database namanya plateNumber
                      carColor: data['carColor'] ?? '-', // Jika tidak disave di db, default '-'
                      classNames: aiService.classNames, 
                      inspectionId: reportId,     // Mengambil ID dari parameter kelas
                      date: formattedDate,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF Laporan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}