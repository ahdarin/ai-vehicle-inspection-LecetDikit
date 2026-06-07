import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AiService {
  Interpreter? _interpreter;

  // Inisialisasi model (manual load dari asset → file)
  Future<void> loadModel() async {
    try {
      final byteData = await rootBundle.load('assets/models/best_float32.tflite');

      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/best_float32.tflite');

      await modelFile.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );

      _interpreter = await Interpreter.fromFile(modelFile);

      print("Model berhasil dimuat!");
    } catch (e) {
      print("Gagal memuat model: $e");
    }
  }

  // Fungsi untuk menjalankan deteksi
  void detect(List<dynamic> input) {
    if (_interpreter == null) return;

    var output = List.generate(
      1,
      (_) => List.generate(
        10,
        (_) => List.filled(8400, 0.0),
      ),
    );

    _interpreter!.run(input, output);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}