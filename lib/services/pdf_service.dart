import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:lecetdikit/services/ai_service.dart';

class PdfService {
  static Future<void> generateAndPrintReport({
    required List<File> images,
    required List<DetectionResult> results,
    required String carModel,
    required String plateNumber,
    required String carColor,
    required List<String> classNames,
    required String inspectionId,
    required String date,
  }) async {
    final pdf = pw.Document();

    // 1. Convert File gambar HP ke format memori PDF
    List<pw.MemoryImage> pdfImages = [];
    for (var file in images) {
      pdfImages.add(pw.MemoryImage(await file.readAsBytes()));
    }

    // 2. Desain Layout PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Inspeksi AI', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f172a'))),
                    pw.SizedBox(height: 4),
                    pw.Text('ID: $inspectionId', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#64748b'))),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal Inspeksi', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748b'))),
                    pw.Text(date, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f172a'))),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColor.fromHex('#0ea5e9'), thickness: 2),
            pw.SizedBox(height: 20),

            // --- INFO KENDARAAN ---
            pw.Row(
              children: [
                _buildInfoBox('KENDARAAN', carModel.isEmpty ? '-' : carModel),
                pw.SizedBox(width: 12),
                _buildInfoBox('PLAT NOMOR', plateNumber.isEmpty ? '-' : plateNumber),
                pw.SizedBox(width: 12),
                _buildInfoBox('WARNA', carColor.isEmpty ? '-' : carColor),
              ]
            ),
            pw.SizedBox(height: 30),

            // --- TABEL KERUSAKAN ---
            pw.Text('Ringkasan Kerusakan', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f172a'))),
            pw.SizedBox(height: 12),
            results.isEmpty 
              ? pw.Text('Tidak terdeteksi adanya kerusakan.', style: pw.TextStyle(color: PdfColor.fromHex('#16a34a')))
              : _buildTable(results, classNames),
            
            pw.SizedBox(height: 30),

            // --- FOTO ANALISIS AI (DENGAN BOUNDING BOX) ---
            // --- FOTO ANALISIS AI (DENGAN BOUNDING BOX) ---
            pw.Text('Analisis Visual AI', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f172a'))),
            pw.SizedBox(height: 12),
            
            ...List.generate(pdfImages.length, (index) {
              final image = pdfImages[index];
              // Hitung rasio asli gambar
              final aspectRatio = (image.width != null && image.height != null) 
                  ? image.width! / image.height! 
                  : 1.5; 
              
              var photoResults = results.where((r) => r.photoIndex == (index + 1)).toList();

              // SOLUSI: Hitung manual lebar kertas A4 (595.27) dikurangi margin kiri-kanan (40 + 40 = 80)
              final double w = PdfPageFormat.a4.width - 80;
              final double h = w / aspectRatio; // Tinggi otomatis menyesuaikan rasio asli

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FOTO ${index + 1}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#64748b'))),
                    pw.SizedBox(height: 8),
                    
                    pw.Container(
                      width: w,
                      height: h,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0')),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        // STACK: Tumpuk gambar asli dengan kotak-kotak deteksi
                        child: pw.Stack(
                          children: [
                            pw.Image(image, width: w, height: h, fit: pw.BoxFit.fill),
                            
                            // Gambar Bounding Box AI
                            ...photoResults.map((res) {
                              // 1. Normalisasi Skala
                              bool isNorm = res.w <= 2.0;
                              double normX = isNorm ? res.x : res.x / 640.0;
                              double normY = isNorm ? res.y : res.y / 640.0;
                              double normW = isNorm ? res.w : res.w / 640.0;
                              double normH = isNorm ? res.h : res.h / 640.0;

                              // 2. Kalikan dengan ukuran gambar di kertas PDF
                              double boxW = normW * w;
                              double boxH = normH * h;
                              double left = (normX * w) - (boxW / 2);
                              double top = (normY * h) - (boxH / 2);

                              // 3. Tentukan Warna berdasarkan Keparahan
                              String damageName = classNames[res.classIndex];
                              bool isHeavy = (damageName == 'Kaca Pecah' || damageName == 'Lampu Pecah' || damageName == 'Ban Kempes') || (res.w * res.h > 0.05);
                              PdfColor color = isHeavy ? PdfColor.fromHex('#ef4444') : PdfColor.fromHex('#f59e0b');

                              // 4. Render Kotaknya
                              return pw.Positioned(
                                left: left,
                                top: top,
                                child: pw.Container(
                                  width: boxW,
                                  height: boxH,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: color, width: 2)
                                  ),
                                  // Label Teks di pojok kotak
                                  child: pw.Stack(
                                    children: [
                                      pw.Positioned(
                                        top: 0,
                                        left: 0,
                                        child: pw.Container(
                                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          color: color,
                                          child: pw.Text(
                                            '${damageName.toUpperCase()} ${(res.confidence * 100).toStringAsFixed(0)}%', 
                                            style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)
                                          )
                                        )
                                      )
                                    ]
                                  )
                                )
                              );
                            }).toList(),
                          ]
                        )
                      )
                    )
                  ]
                )
              );
            }),

            pw.SizedBox(height: 30),

            // --- DISCLAIMER ---
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f8fafc'), border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0')), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
              child: pw.Text(
                'Catatan: Laporan ini dihasilkan secara otomatis oleh LecetDikit AI berdasarkan gambar yang diunggah. Estimasi keparahan merupakan perkiraan kasar heuristik Computer Vision dan dapat berbeda dengan penilaian struktural oleh bengkel resmi.',
                style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748b')),
              )
            )
          ];
        },
      ),
    );

    // 3. Render dan Tampilkan PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Inspeksi_${inspectionId}.pdf', 
    );
  }

  // --- KOMPONEN BANTUAN UI PDF --- //
  
  static pw.Widget _buildInfoBox(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#f8fafc'),
          border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0')),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#64748b'), fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f172a'))),
          ]
        )
      )
    );
  }

  static pw.Widget _buildTable(List<DetectionResult> results, List<String> classNames) {
    return pw.TableHelper.fromTextArray(
      headers: ['Temuan AI', 'Tingkat', 'Confidence', 'Posisi Foto'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#475569')),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#f1f5f9')),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      data: List<List<String>>.generate(
        results.length,
        (row) {
          final res = results[row];
          final damageName = classNames[res.classIndex];
          final isHeavy = (damageName == 'Kaca Pecah' || damageName == 'Lampu Pecah' || damageName == 'Ban Kempes') || (res.w * res.h > 0.05);
          
          return [
            damageName,
            isHeavy ? 'BERAT' : 'RINGAN',
            '${(res.confidence * 100).toStringAsFixed(1)}%',
            'Foto ${res.photoIndex}'
          ];
        },
      ),
    );
  }
}