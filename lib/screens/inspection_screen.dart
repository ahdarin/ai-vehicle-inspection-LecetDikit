import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/widgets/bounding_box_painter.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isAnalyzed = false;
  List<DetectionResult> _results = [];

  // Controller untuk form
  final _modelController = TextEditingController();
  final _platController = TextEditingController();
  final _warnaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _aiService.loadModel();
  }

  @override
  void dispose() {
    _aiService.dispose();
    _modelController.dispose();
    _platController.dispose();
    _warnaController.dispose();
    super.dispose();
  }

  // Tahap 1: Pilih Gambar
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isAnalyzed = false; // Reset hasil jika foto diganti
        _results = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Tahap 2: Analisis Gambar
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final Uint8List bytes = await _selectedImage!.readAsBytes();
      final results = await _aiService.detectObject(bytes);

      setState(() {
        _isAnalyzing = false;
        _isAnalyzed = true;
        if (results != null) _results = results;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menganalisis: $e')));
    }
  }

  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _isAnalyzed = false;
      _results = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Judul Halaman
        Text('Inspeksi Kendaraan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        const SizedBox(height: 8),
        Text('Unggah foto kendaraan untuk mendeteksi kerusakan secara otomatis menggunakan AI.',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        // Form Detail Kendaraan
        Text('Detail Kendaraan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        _buildTextField('Merk & Model Mobil', 'Contoh: Toyota Camry', _modelController, colorScheme),
        _buildTextField('Nomor Plat', 'Contoh: B 1234 XYZ', _platController, colorScheme),
        _buildTextField('Warna Mobil', 'Contoh: Hitam Metalik', _warnaController, colorScheme),
        const SizedBox(height: 24),

        // Area Foto / Preview
        if (_selectedImage == null) 
          _buildUploadArea(colorScheme)
        else 
          _buildImagePreview(colorScheme),

        const SizedBox(height: 24),

        // Tombol Analisis
        ElevatedButton.icon(
          onPressed: (_selectedImage != null && !_isAnalyzing && !_isAnalyzed) ? _analyzeImage : null,
          icon: _isAnalyzing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_isAnalyzed ? Icons.check_circle : Icons.analytics),
          label: Text(_isAnalyzing ? 'Menganalisis...' : (_isAnalyzed ? 'Analisis Selesai' : 'Analisis Kerusakan')),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAnalyzed ? colorScheme.surfaceTint : colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),

        const SizedBox(height: 24),

        // Hasil Deteksi
        if (_isAnalyzed) _buildResultCards(colorScheme),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(Icons.add_a_photo, size: 30, color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('Pilih Foto Kendaraan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Gunakan foto yang jelas dan terang', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.file(_selectedImage!, width: double.infinity, fit: BoxFit.fitWidth),
                if (_isAnalyzed)
                  Positioned.fill(
                    child: CustomPaint(painter: BoundingBoxPainter(_results, _aiService.classNames)),
                  ),
              ],
            ),
          ),
          // Tombol X untuk membatalkan foto
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _resetForm,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultCards(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('HASIL DETEKSI AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(4)),
              child: Text('${_results.length} KERUSAKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onErrorContainer)),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (_results.isEmpty)
           const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Tidak Terdeteksi Kerusakan', style: TextStyle(fontWeight: FontWeight.bold)))),
        ..._results.map((res) {
          String damageName = _aiService.classNames[res.classIndex].toUpperCase();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: colorScheme.errorContainer, child: Icon(Icons.car_crash, color: colorScheme.error)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(damageName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Confidence: ${(res.confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
          );
        }),
      ],
    );
  }
}