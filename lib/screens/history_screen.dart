import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lecetdikit/screens/history_detail_screen.dart';
import 'package:lecetdikit/services/database_service.dart';
import 'package:lecetdikit/screens/report_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.primary, // Otomatis menyesuaikan warna Light/Dark untuk tombol Back
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- JUDUL DI ATAS & TEKS KECIL ---
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

          // --- LIST DATA DARI FIRESTORE ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.streamInspections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Belum ada riwayat inspeksi.', style: TextStyle(color: colorScheme.onSurfaceVariant)));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final String reportId = data['id'] ?? '';
                    final String vehicleName = data['vehicleName'] ?? 'Kendaraan';
                    final String plateNumber = data['plateNumber'] ?? '-';
                    final String status = data['status'] ?? 'AMAN';
                    final List<dynamic> findings = data['findings'] ?? [];
                    final String base64Image = data['imageBase64'] ?? '';
                    
                    String timeDisplay = 'Baru saja';
                    if (data['timestamp'] != null) {
                      final Timestamp timestamp = data['timestamp'];
                      timeDisplay = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(timestamp.toDate());
                    }

                    // --- DESAIN KARTU SAMA DENGAN DASHBOARD + TOMBOL ---
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Gambar Thumbnail & Status (Di Bagian Atas)
                          SizedBox(
                            height: 160, 
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    base64Image.isNotEmpty 
                                      ? Image.memory(base64Decode(base64Image), fit: BoxFit.cover)
                                      : Image.network('https://images.unsplash.com/photo-1494976388531-d1058494cdd8?q=80&w=600', fit: BoxFit.cover),
                                  ],
                                ),
                                Positioned(
                                  top: 12, right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: (status == 'AMAN' ? const Color(0xFF006A60) : colorScheme.error).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: status == 'AMAN' ? const Color(0xFF006A60) : colorScheme.error, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(status, style: TextStyle(color: status == 'AMAN' ? const Color(0xFF006A60) : colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Detail Informasi Laporan & Tombol Detail (Di Bagian Bawah)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(vehicleName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('ID: ${reportId.substring(0, 5).toUpperCase()}', style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Plat: $plateNumber • $timeDisplay', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                                const SizedBox(height: 16),
                                
                                // Chips Temuan
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: findings.map((finding) {
                                    final isError = !finding.toString().toLowerCase().contains('lulus');
                                    return _buildFindingChip(finding, isError ? colorScheme.errorContainer.withOpacity(0.5) : colorScheme.surfaceContainerHighest, isError ? colorScheme.error : colorScheme.onSurfaceVariant, isError: isError, borderColor: isError ? colorScheme.error.withOpacity(0.3) : Colors.transparent);
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Tombol Detail Laporan
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryDetailScreen(reportId: reportId)));
                                    },
                                    icon: const Icon(Icons.analytics_outlined),
                                    label: const Text('Detail Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: colorScheme.outlineVariant),
                                      foregroundColor: colorScheme.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
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

  Widget _buildFindingChip(String label, Color bgColor, Color textColor, {bool isError = false, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: borderColor ?? Colors.transparent)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontFamily: 'Courier', fontWeight: isError ? FontWeight.bold : FontWeight.w600)),
    );
  }
}