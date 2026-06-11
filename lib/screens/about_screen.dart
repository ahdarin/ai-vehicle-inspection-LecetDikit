import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('LecetDikit AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.asset(
                'assets/images/logo.png',
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.car_crash,
                  color: colorScheme.primary,
                  size: 100,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- RINGKASAN UTAMA ---
          Text(
            'Inovasi Inspeksi Kendaraan berbasis Computer Vision',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            'LecetDikit AI adalah platform otomotif cerdas yang dirancang untuk mendeteksi, mengklasifikasi, dan menganalisis tingkat kerusakan eksterior kendaraan secara instan menggunakan kecerdasan buatan tingkat tinggi.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // --- SPESIFIKASI MODEL AI ---
          const SizedBox(height: 16),
          _buildSectionHeader('Arsitektur & Model AI', colorScheme),
          const SizedBox(height: 12),
          Text(
            'Sistem inti deteksi dibangun menggunakan arsitektur YOLOv8n (YOLOv8 Nano) dari Ultralytics, yang dioptimalkan khusus untuk mendeteksi objek secara real-time dengan efisiensi komputasi tinggi pada perangkat mobile.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 12),
          _buildMetricRow('Arsitektur Utama', 'YOLOv8n (Nano)', colorScheme),
          _buildMetricRow('Kerangka Kerja', 'PyTorch 🚀 -> TensorFlow Lite (TFLite)', colorScheme),
          _buildMetricRow('Ukuran Model Eksport', '11.7 MB (best_float32.tflite)', colorScheme),
          _buildMetricRow('Target Resolusi Input', '640x640 Piksel', colorScheme),
          const SizedBox(height: 24),

          // --- DATASET & DATA LATIH ---
          _buildSectionHeader('Sumber & Distribusi Data Latih', colorScheme),
          const SizedBox(height: 12),
          Text(
            'Model dilatih menggunakan dataset komprehensif kendaraan rusak (CarDD Dataset) yang bersumber dari Kaggle. Seluruh anotasi data telah dikonversi secara presisi dari format COCO ke format bounding box YOLO.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Total Gambar Training', '2,816 Gambar', colorScheme),
          _buildMetricRow('Total Gambar Validasi', '810 Gambar', colorScheme),
          _buildMetricRow('Jumlah Kelas Deteksi', '6 Kelas Utama', colorScheme),
          const SizedBox(height: 12),
          
          // Daftar Kelas
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _buildClassChip('Dent (Penyok)', colorScheme),
              _buildClassChip('Scratch (Goresan)', colorScheme),
              _buildClassChip('Crack (Retak)', colorScheme),
              _buildClassChip('Glass Shatter (Kaca Pecah)', colorScheme),
              _buildClassChip('Lamp Broken (Lampu Rusak)', colorScheme),
              _buildClassChip('Tire Flat (Ban Kempes)', colorScheme),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // --- VISUALISASI EVALUASI TRAINING ---
          const SizedBox(height: 16),
          _buildSectionHeader('Kurva Metrik & Evaluasi Pelatihan', colorScheme),
          const SizedBox(height: 8),
          Text(
            'Proses pelatihan berjalan optimal sepanjang 50 Epoch menggunakan akselerasi GPU Tesla T4. Grafik di bawah menunjukkan penurunan loss yang konsisten baik pada data training maupun validasi.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          
          _buildImageCard('Kurva Loss Pelatihan & Validasi', 'assets/images/training_val_loss_curve.png', colorScheme),
          _buildImageCard('Kurva Precision-Recall (Box PR Curve)', 'assets/images/BoxPR_curve.png', colorScheme),
          _buildImageCard('Confusion Matrix Hasil Validasi', 'assets/images/confusion_matrix.png', colorScheme),
          
          const SizedBox(height: 24),
          const Divider(),

          // --- VISUALISASI BATCH PREDIKSI ---
          const SizedBox(height: 16),
          _buildSectionHeader('Visualisasi Batches: Ground Truth vs Prediksi', colorScheme),
          const SizedBox(height: 12),
          Text(
            'Perbandingan visual di bawah membuktikan akurasi penempatan Bounding Box oleh model AI dalam mendeteksi lokasi defect secara presisi jika disandingkan dengan label asli (Ground Truth).',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          
          _buildImageCard('Label Asli / Ground Truth (Batch 0)', 'assets/images/val_batch0_labels.jpeg', colorScheme),
          _buildImageCard('Hasil Prediksi Model AI (Batch 0)', 'assets/images/val_batch0_pred.jpeg', colorScheme),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'LecetDikit AI v1.0.0 • Universitas Andalas',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- REUSABLE COMPONENT WIDGETS ---
  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
    );
  }

  Widget _buildMetricRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildClassChip(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildImageCard(String title, String assetPath, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary)),
          ),
          Image.asset(
            assetPath,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, color: colorScheme.error, size: 32),
                    const SizedBox(height: 8),
                    Text('Gambar tidak ditemukan di asset', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}