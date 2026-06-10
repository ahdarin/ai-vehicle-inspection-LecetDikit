import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/widgets/bounding_box_painter.dart';
import 'package:lecetdikit/services/pdf_service.dart';
import 'package:lecetdikit/services/database_service.dart';

class ReportScreen extends StatefulWidget {
  final List<File> images;
  final List<DetectionResult> results;
  final String carModel;
  final String plateNumber;
  final String carColor;

  const ReportScreen({
    super.key,
    required this.images,
    required this.results,
    required this.carModel,
    required this.plateNumber,
    required this.carColor,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final AiService _aiService = AiService();
  final DatabaseService _dbService = DatabaseService();
  
  bool _isSaved = false;
  late String _inspectionId;
  late String _formattedDate;

  @override
  void initState() {
    super.initState();
    _inspectionId = _generateInspectionID();
    _formattedDate = _getFormattedDate();
    
    // Otomatis simpan data saat halaman diload
    _saveToDatabase();
  }

  Future<void> _saveToDatabase() async {
    if (_isSaved) return;

    try {
      final statusUmum = _calculateGeneralStatus(widget.results);
      
      // SINKRONISASI DATA: Kita merubah objek deteksi menjadi Map agar 100% detail tersimpan
      final List<Map<String, dynamic>> detailedFindings = widget.results.map((r) {
        return {
          'classIndex': r.classIndex,
          'confidence': r.confidence,
          'photoIndex': r.photoIndex,
          'x': r.x,
          'y': r.y,
          'w': r.w,
          'h': r.h,
        };
      }).toList();

      await _dbService.saveInspection(
        reportId: _inspectionId,
        vehicleName: widget.carModel.isNotEmpty ? widget.carModel : 'Mobil Tidak Dikenal',
        plateNumber: widget.plateNumber.isNotEmpty ? widget.plateNumber : '-',
        status: statusUmum,
        images: widget.images,
        findings: detailedFindings,
      );
      
      _isSaved = true;
    } catch (e) {
      debugPrint('Gagal menyimpan ke database: $e');
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _generateInspectionID() {
    final now = DateTime.now();
    return 'LD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  bool _isHeavyDamage(DetectionResult res) {
    String damageType = _aiService.classNames[res.classIndex];
    if (damageType == 'Kaca Pecah' || damageType == 'Lampu Pecah' || damageType == 'Ban Kempes') return true; 
    double area = res.w * res.h;
    double maxLength = res.w > res.h ? res.w : res.h;

    if (damageType == 'Goresan' && maxLength > 0.40) return true;
    if (damageType == 'Retak' && maxLength > 0.25) return true;
    if (damageType == 'Penyok' && area > 0.15) return true;
    
    return false;
  }
  
  String _calculateGeneralStatus(List<DetectionResult> results) {
    if (results.isEmpty) return 'Sangat Baik';
    if (results.any((res) => _isHeavyDamage(res))) return 'Butuh Perbaikan Segera';
    if (results.length <= 2) return 'Minor / Perhatian';
    return 'Perawatan Eksterior';
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
    final isSafe = widget.results.isEmpty;
    final statusUmum = _calculateGeneralStatus(widget.results);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_inspectionId, style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
              Text(_formattedDate, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hasil Analisis', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          if (widget.carModel.isNotEmpty || widget.plateNumber.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('${widget.carModel} • ${widget.plateNumber}', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant))),
          
          const SizedBox(height: 24),

          ...List.generate(widget.images.length, (index) {
            int currentPhotoIndex = index + 1;
            var photoResults = widget.results.where((r) => r.photoIndex == currentPhotoIndex).toList();

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
                        Image.file(widget.images[index], width: double.infinity, fit: BoxFit.fitWidth),
                        Positioned.fill(child: CustomPaint(painter: BoundingBoxPainter(photoResults, _aiService.classNames))),
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
                      Text('${widget.results.length} Titik', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface))
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
            ...widget.results.map((res) {
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
          ElevatedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyiapkan dokumen PDF...')));
              await PdfService.generateAndPrintReport(
                images: widget.images,
                results: widget.results,
                carModel: widget.carModel,
                plateNumber: widget.plateNumber,
                carColor: widget.carColor,
                classNames: _aiService.classNames,
                inspectionId: _inspectionId,
                date: _formattedDate,
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