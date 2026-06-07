import 'package:flutter/material.dart';
import 'package:lecetdikit/services/ai_service.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> results;
  final List<String> classNames;

  BoundingBoxPainter(this.results, this.classNames);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint textBackgroundPaint = Paint()
      ..style = PaintingStyle.fill;

    for (var result in results) {
      Color color = _getColor(result.classIndex);
      boxPaint.color = color;
      textBackgroundPaint.color = color;

      // 1. Ubah semua format koordinat menjadi persentase (0.0 sampai 1.0)
      bool isNormalized = result.w <= 2.0;
      double normX = isNormalized ? result.x : result.x / 640.0;
      double normY = isNormalized ? result.y : result.y / 640.0;
      double normW = isNormalized ? result.w : result.w / 640.0;
      double normH = isNormalized ? result.h : result.h / 640.0;

      // 2. Kalikan persentase tersebut dengan ukuran asli gambar di layar HP (Size)
      double xCenter = normX * size.width;
      double yCenter = normY * size.height;
      double boxWidth = normW * size.width;
      double boxHeight = normH * size.height;

      double left = xCenter - (boxWidth / 2);
      double top = yCenter - (boxHeight / 2);
      double right = xCenter + (boxWidth / 2);
      double bottom = yCenter + (boxHeight / 2);

      // Gambar Kotak
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), boxPaint);

      // Siapkan Teks
      String label = '${classNames[result.classIndex].toUpperCase()} ${(result.confidence * 100).toStringAsFixed(0)}%';
      TextSpan span = TextSpan(style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), text: label);
      TextPainter textPainter = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      textPainter.layout();

      // Gambar Background Teks
      canvas.drawRect(
        Rect.fromLTWH(left, top - textPainter.height - 4, textPainter.width + 8, textPainter.height + 4),
        textBackgroundPaint,
      );

      // Gambar Teks
      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 2));
    }
  }

  Color _getColor(int classIndex) {
    switch (classIndex) {
      case 0: return Colors.orange; // dent
      case 1: return Colors.blue;   // scratch
      case 2: return Colors.red;    // crack
      case 3: return Colors.purple; // glass_shatter
      case 4: return Colors.yellow; // lamp_broken
      case 5: return Colors.teal;   // tire_flat
      default: return Colors.green;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}