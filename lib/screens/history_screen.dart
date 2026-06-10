import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lecetdikit/services/database_service.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/screens/history_detail_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AiService _aiService = AiService();

  void _confirmDelete(String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini beserta fotonya secara permanen?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _dbService.deleteInspection(reportId);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.primary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Inspeksi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(height: 6),
                Text('Daftar seluruh laporan pengecekan kendaraan Anda.', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.streamInspections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('Belum ada riwayat inspeksi.', style: TextStyle(color: colorScheme.onSurfaceVariant)));

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final String reportId = data['id'] ?? '';
                    final String vehicleName = data['vehicleName'] ?? 'Kendaraan';
                    final String plateNumber = data['plateNumber'] ?? '-';
                    final String status = data['status'] ?? 'Sangat Baik';
                    
                    // Baca gambar lokal
                    final List<dynamic> localPaths = data['localImagePaths'] ?? [];
                    final String localThumb = localPaths.isNotEmpty ? localPaths[0].toString() : '';

                    // Menentukan warna
                    Color statusColor = Colors.green;
                    if (status == 'Butuh Perbaikan Segera') statusColor = Colors.red;
                    if (status == 'Minor / Perhatian') statusColor = Colors.orange;

                    String timeDisplay = 'Baru saja';
                    if (data['timestamp'] != null) {
                      timeDisplay = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format((data['timestamp'] as Timestamp).toDate());
                    }

                    // Menghindari error tipe data dengan membaca list dynamic secara aman
                    final List<dynamic> rawFindings = data['findings'] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 160, 
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                localThumb.isNotEmpty
                                  ? Image.file(File(localThumb), fit: BoxFit.cover, errorBuilder: (ctx, err, stk) => Container(color: colorScheme.surfaceContainerHighest, child: const Icon(Icons.broken_image, size: 40)))
                                  : Container(color: colorScheme.surfaceContainerHighest, child: const Icon(Icons.directions_car, size: 40)),
                                Positioned(
                                  top: 12, right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text(vehicleName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    Text('ID: ${reportId.substring(0, 8)}', style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Plat: $plateNumber • $timeDisplay', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                                const SizedBox(height: 16),
                                
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: rawFindings.map((finding) {
                                    if (finding is Map) {
                                      int clsIdx = finding['classIndex'] ?? 0;
                                      String damageName = _aiService.classNames[clsIdx];
                                      bool isHeavy = damageName == 'Kaca Pecah' || damageName == 'Lampu Pecah' || damageName == 'Ban Kempes';
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: isHeavy ? colorScheme.errorContainer.withOpacity(0.5) : colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6), border: Border.all(color: isHeavy ? colorScheme.error.withOpacity(0.3) : Colors.transparent)),
                                        child: Text(damageName.toUpperCase(), style: TextStyle(color: isHeavy ? colorScheme.error : colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
                                      );
                                    }
                                    return const SizedBox();
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Tombol Detail & Delete
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 45,
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryDetailScreen(reportId: reportId))),
                                          icon: const Icon(Icons.analytics_outlined),
                                          label: const Text('Detail Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          style: OutlinedButton.styleFrom(side: BorderSide(color: colorScheme.outlineVariant), foregroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      height: 45, width: 45,
                                      decoration: BoxDecoration(color: colorScheme.errorContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: colorScheme.error.withOpacity(0.3))),
                                      child: IconButton(
                                        icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 22),
                                        onPressed: () => _confirmDelete(reportId),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}