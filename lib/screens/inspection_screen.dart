import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/screens/report_screen.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedImages = []; // Ubah menjadi List untuk max 5 foto
  bool _isAnalyzing = false;

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

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 5 foto kendaraan!')));
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        // Bisa pilih multiple dari galeri
        final List<XFile> pickedFiles = await _picker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          setState(() {
            for (var file in pickedFiles) {
              if (_selectedImages.length < 5) _selectedImages.add(File(file.path));
            }
          });
        }
      } else {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() {
            _selectedImages.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _analyzeImages() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isAnalyzing = true);

    try {
      List<DetectionResult> allResults = [];
      
      // Loop ke semua foto yang diunggah
      for (int i = 0; i < _selectedImages.length; i++) {
        final Uint8List bytes = await _selectedImages[i].readAsBytes();
        final results = await _aiService.detectObject(bytes, photoIndex: i + 1); // photoIndex mulai dari 1
        if (results.isNotEmpty) allResults.addAll(results);
      }

      setState(() => _isAnalyzing = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              images: _selectedImages,
              results: allResults,
              carModel: _modelController.text,
              plateNumber: _platController.text,
              carColor: _warnaController.text,
            ),
          ),
        ).then((_) => _resetForm());
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _resetForm() {
    setState(() {
      _selectedImages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Inspeksi Kendaraan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        const SizedBox(height: 8),
        Text('Unggah hingga 5 foto kendaraan dari berbagai sisi.', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        _buildTextField('Merk & Model Mobil', 'Contoh: Toyota Camry', _modelController, colorScheme),
        _buildTextField('Nomor Plat', 'Contoh: B 1234 XYZ', _platController, colorScheme),
        _buildTextField('Warna Mobil', 'Contoh: Hitam Metalik', _warnaController, colorScheme),
        const SizedBox(height: 24),

        // Pilihan Foto
        Text('Foto Kendaraan (${_selectedImages.length}/5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        _buildImageGallery(colorScheme),

        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: (_selectedImages.isNotEmpty && !_isAnalyzing) ? _analyzeImages : null,
          icon: _isAnalyzing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.analytics),
          label: Text(_isAnalyzing ? 'Menganalisis ${_selectedImages.length} Foto...' : 'Analisis Kerusakan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: colorScheme.surface,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary)),
        ),
      ),
    );
  }

  Widget _buildImageGallery(ColorScheme colorScheme) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length < 5 ? _selectedImages.length + 1 : 5,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pilih Sumber Foto', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              // Kamera
                              Expanded(
                                child: InkWell(
                                  onTap: () { 
                                    Navigator.pop(context); 
                                    _pickImage(ImageSource.camera); 
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: colorScheme.primaryContainer.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.camera_alt, size: 48, color: colorScheme.primary),
                                        const SizedBox(height: 12),
                                        Text('Kamera', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Galeri
                              Expanded(
                                child: InkWell(
                                  onTap: () { 
                                    Navigator.pop(context); 
                                    _pickImage(ImageSource.gallery); 
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.photo_library, size: 48, color: colorScheme.primary),
                                        const SizedBox(height: 12),
                                        Text('Galeri', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5), 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(Icons.add_a_photo, color: colorScheme.primary), 
                    const SizedBox(height: 4), 
                    const Text('Tambah', style: TextStyle(fontSize: 12))
                  ]
                ),
              ),
            );
          }
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover)),
              ),
              Positioned(
                top: 4, right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                  child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                ),
              ),
              Positioned(
                bottom: 4, left: 4,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text('Foto ${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              )
            ],
          );
        },
      ),
    );
  }
}