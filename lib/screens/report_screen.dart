import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/widgets/bounding_box_painter.dart';
import 'package:lecetdikit/services/pdf_service.dart';

class ReportScreen extends StatelessWidget {
  final List<File> images;
  final List<DetectionResult> results;
  final String carModel;
  final String plateNumber;
  final String carColor;
  final AiService _aiService = AiService();

  ReportScreen({
    super.key,
    required this.images,
    required this.results,
    required this.carModel,
    required this.plateNumber,
    required this.carColor,
  });

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _generateInspectionID() {
    final now = DateTime.now();
    // Format: LD-TAHUNBULANHARI-JAMMENITDETIK
    return 'LD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  bool _isHeavyDamage(DetectionResult res) {
    String damageType = _aiService.classNames[res.classIndex];

    // 1. Kerusakan Fatal (Selalu Berat berapapun ukurannya)
    if (damageType == 'Kaca Pecah' || damageType == 'Lampu Pecah' || damageType == 'Ban Kempes') {
      return true; 
    }

    // 2. Ambil metrik geometris
    double area = res.w * res.h; // Luas kotak
    double maxLength = res.w > res.h ? res.w : res.h; // Sisi terpanjang (lebar atau tinggi)

    // 3. Logika Spesifik per Kelas
    if (damageType == 'Goresan') {
      // Jika panjang goresan membentang lebih dari 40% ukuran foto, anggap BERAT
      if (maxLength > 0.40) return true;
    } 
    else if (damageType == 'Retak') {
      // Retak lebih fatal dari goresan, jika lebih dari 25% panjang foto, anggap BERAT
      if (maxLength > 0.25) return true;
    } 
    else if (damageType == 'Penyok') {
      // Penyok dilihat dari luas area. Kita naikkan ke 15% untuk toleransi foto close-up
      if (area > 0.15) return true;
    }

    // Jika tidak memenuhi syarat "Berat" di atas, berarti Ringan
    return false;
  }
  
  String _calculateGeneralStatus(List<DetectionResult> results) {
    if (results.isEmpty) return 'Sangat Baik';
    
    // Jika ada minimal 1 kerusakan "Berat", status langsung "Kritis"
    bool hasHeavyDamage = results.any((res) => _isHeavyDamage(res));
    if (hasHeavyDamage) return 'Butuh Perbaikan Segera';

    // Jika cuma 1-2 lecet ringan
    if (results.length <= 2) return 'Minor / Perhatian';
    
    // Jika lecet ringan tapi banyak
    return 'Perawatan Eksterior';
  }

  // Fungsi tambahan untuk menentukan warna status umum
  Color _getStatusColor(String status) {
    if (status == 'Sangat Baik') return Colors.green;
    if (status == 'Butuh Perbaikan Segera') return Colors.red;
    if (status == 'Minor / Perhatian') return Colors.orange;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSafe = results.isEmpty;
    
    // Hitung status dan warna di sini agar rapi
    final statusUmum = _calculateGeneralStatus(results);
    final statusColor = _getStatusColor(statusUmum);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LecetDikit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info ID & Tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_generateInspectionID(), style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
              Text(_getFormattedDate(), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hasil Analisis', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          if (carModel.isNotEmpty || plateNumber.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('$carModel • $plateNumber', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant))),
          
          const SizedBox(height: 24),

          // Render semua foto yang dianalisis
          ...List.generate(images.length, (index) {
            int currentPhotoIndex = index + 1;
            // Ambil HANYA kotak deteksi untuk foto spesifik ini
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
                        Image.file(images[index], width: double.infinity, fit: BoxFit.fitWidth),
                        Positioned.fill(child: CustomPaint(painter: BoundingBoxPainter(photoResults, _aiService.classNames))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          // Metrics Grid
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
                      // Menggunakan text dinamis beserta warnanya
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
          
          // Daftar Temuan
          if (isSafe)
            const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Kondisi eksterior sangat baik.')))
          else
            ...results.map((res) {
              String damageName = _aiService.classNames[res.classIndex];
              bool isHeavy = _isHeavyDamage(res); 
              
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

          // Tombol PDF
          ElevatedButton.icon(
            onPressed: () async {
              // Tampilkan indikator proses
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyiapkan dokumen PDF...')));

              // Panggil PdfService
              await PdfService.generateAndPrintReport(
                images: images,
                results: results,
                carModel: carModel,
                plateNumber: plateNumber,
                carColor: carColor,
                classNames: _aiService.classNames,
                inspectionId: _generateInspectionID(),
                date: _getFormattedDate(),
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
      ),
    );
  }
}