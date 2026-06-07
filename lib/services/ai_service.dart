import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

// Class untuk menyimpan hasil akhir deteksi
class DetectionResult {
  final int classIndex;
  final double confidence;
  final double x;
  final double y;
  final double w;
  final double h;

  DetectionResult({
    required this.classIndex,
    required this.confidence,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  @override
  String toString() {
    return 'Kelas: $classIndex, Yakin: ${(confidence * 100).toStringAsFixed(1)}%, Kotak: [x:$x, y:$y, w:$w, h:$h]';
  }
}

class AiService {
  Interpreter? _interpreter;

  // Nama kelas sesuai urutan saat Anda melatih model (pastikan urutannya benar)
  final List<String> classNames = [
    'dent', 'scratch', 'crack', 'glass_shatter', 'lamp_broken', 'tire_flat'
  ];

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

  Future<List<DetectionResult>> detectObject(Uint8List imageBytes) async {
    if (_interpreter == null) return [];

    try {
      // 1. Preprocessing Gambar
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

      // 2. Siapkan Output
      var output = List.generate(1, (_) => List.generate(10, (_) => List.filled(8400, 0.0)));

      // 3. Inference
      _interpreter!.run(input, output);

      // 4. Post-Processing (Menyaring 8400 kotak)
      List<DetectionResult> results = [];
      
      // Loop untuk 8400 prediksi
      for (int i = 0; i < 8400; i++) {
        double maxConfidence = 0.0;
        int maxClassIndex = -1;

        // Cek skor untuk ke-6 kelas (index 4 sampai 9 di array)
        for (int c = 0; c < 6; c++) {
          double confidence = output[0][4 + c][i];
          if (confidence > maxConfidence) {
            maxConfidence = confidence;
            maxClassIndex = c;
          }
        }

        // Jika AI yakin di atas 50% (0.5), kita simpan kotaknya
        if (maxConfidence > 0.50) {
          double xCenter = output[0][0][i];
          double yCenter = output[0][1][i];
          double width = output[0][2][i];
          double height = output[0][3][i];

          results.add(DetectionResult(
            classIndex: maxClassIndex,
            confidence: maxConfidence,
            x: xCenter,
            y: yCenter,
            w: width,
            h: height,
          ));
        }
      }

      print("✅ Ditemukan ${results.length} potensi kerusakan!");
      for (var res in results) {
        print("- ${classNames[res.classIndex]}: ${(res.confidence * 100).toStringAsFixed(1)}%");
      }

      // Catatan: Nanti kita butuh NMS (Non-Maximum Suppression) di sini agar kotak tidak menumpuk,
      // tapi kita tes deteksi mentahnya dulu.
      return results;

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