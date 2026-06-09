import 'dart:math'; // Tambahkan untuk fungsi max & min
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

// Tambahkan photoIndex agar kita tahu ini lecet di foto ke berapa
class DetectionResult {
  final int classIndex;
  final double confidence;
  final double x;
  final double y;
  final double w;
  final double h;
  final int photoIndex; // Indikator Foto

  DetectionResult({
    required this.classIndex,
    required this.confidence,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.photoIndex,
  });
}

class AiService {
  Interpreter? _interpreter;

  final List<String> classNames = [
    'Penyok',       // index 0: dent
    'Goresan',      // index 1: scratch
    'Retak',        // index 2: crack
    'Kaca Pecah',   // index 3: glass_shatter
    'Lampu Pecah',  // index 4: lamp_broken
    'Ban Kempes'    // index 5: tire_flat
  ];

  // ... (biarkan fungsi loadModel tetap sama seperti sebelumnya) ...
  Future<void> loadModel() async {
    try {
      final byteData = await rootBundle.load('assets/models/best_float32.tflite');
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/best_float32.tflite');

      await modelFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      _interpreter = await Interpreter.fromFile(modelFile);
      print("✅ Model AI siap digunakan!");
    } catch (e) {
      print("❌ Gagal memuat model: $e");
    }
  }

  // --- FUNGSI IOU & NMS UNTUK MENCEGAH KOTAK BERTUMPUK ---
  double _calculateIoU(DetectionResult a, DetectionResult b) {
    double x1 = a.x - a.w / 2, y1 = a.y - a.h / 2;
    double x2 = a.x + a.w / 2, y2 = a.y + a.h / 2;
    double x1_b = b.x - b.w / 2, y1_b = b.y - b.h / 2;
    double x2_b = b.x + b.w / 2, y2_b = b.y + b.h / 2;

    double interX1 = max(x1, x1_b), interY1 = max(y1, y1_b);
    double interX2 = min(x2, x2_b), interY2 = min(y2, y2_b);

    if (interX2 <= interX1 || interY2 <= interY1) return 0.0;

    double interArea = (interX2 - interX1) * (interY2 - interY1);
    return interArea / ((a.w * a.h) + (b.w * b.h) - interArea);
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> boxes, double iouThreshold) {
    List<DetectionResult> finalBoxes = [];
    Map<int, List<DetectionResult>> grouped = {};
    
    // Kelompokkan berdasarkan jenis kelas
    for (var box in boxes) {
      grouped.putIfAbsent(box.classIndex, () => []).add(box);
    }

    for (var classBoxes in grouped.values) {
      // Urutkan dari confidence tertinggi ke terendah
      classBoxes.sort((a, b) => b.confidence.compareTo(a.confidence));
      while (classBoxes.isNotEmpty) {
        var bestBox = classBoxes.first;
        finalBoxes.add(bestBox);
        classBoxes.removeAt(0);
        // Hapus kotak lain yang menumpuk di atas bestBox (IoU > batas)
        classBoxes.removeWhere((box) => _calculateIoU(bestBox, box) > iouThreshold);
      }
    }
    return finalBoxes;
  }
  // ---------------------------------------------------------

  // Tambahkan parameter photoIndex
  Future<List<DetectionResult>> detectObject(Uint8List imageBytes, {required int photoIndex}) async {
    if (_interpreter == null) return [];

    try {
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return [];
      img.Image resizedImage = img.copyResize(originalImage, width: 640, height: 640);

      var inputList = Float32List(1 * 640 * 640 * 3);
      var index = 0;
      for (var y = 0; y < 640; y++) {
        for (var x = 0; x < 640; x++) {
          var pixel = resizedImage.getPixel(x, y);
          inputList[index++] = pixel.r / 255.0;
          inputList[index++] = pixel.g / 255.0;
          inputList[index++] = pixel.b / 255.0;
        }
      }
      var input = inputList.reshape([1, 640, 640, 3]);
      var output = List.generate(1, (_) => List.generate(10, (_) => List.filled(8400, 0.0)));

      _interpreter!.run(input, output);

      List<DetectionResult> rawResults = [];
      for (int i = 0; i < 8400; i++) {
        double maxConfidence = 0.0;
        int maxClassIndex = -1;
        for (int c = 0; c < 6; c++) {
          double confidence = output[0][4 + c][i];
          if (confidence > maxConfidence) {
            maxConfidence = confidence;
            maxClassIndex = c;
          }
        }
        if (maxConfidence > 0.50) { // Nilai threshold AI
          rawResults.add(DetectionResult(
            classIndex: maxClassIndex,
            confidence: maxConfidence,
            x: output[0][0][i], y: output[0][1][i],
            w: output[0][2][i], h: output[0][3][i],
            photoIndex: photoIndex, // Simpan nomor foto
          ));
        }
      }

      // Terapkan NMS (Threshold IoU 0.45, artinya jika tumpang tindih 45%, buang yang terendah)
      return _applyNMS(rawResults, 0.45);

    } catch (e) {
      print("❌ Error saat deteksi: $e");
      return [];
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}