import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lecetdikit/screens/history_detail_screen.dart';
import 'package:lecetdikit/screens/history_screen.dart';
import 'package:lecetdikit/screens/inspection_screen.dart';
import 'package:lecetdikit/screens/profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lecetdikit/services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  final List<Widget> _pages = [
    const HomeView(),             // Index 0: Beranda
    const InspectionScreen(),     // Index 1: Inspeksi
    const ProfileScreen(),        // Index 2: Profil
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.car_crash, color: colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 12),
            Text(
              'LecetDikit',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 20),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  final activeUser = snapshot.data ?? currentUser;
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: activeUser?.photoURL != null ? NetworkImage(activeUser!.photoURL!) : null,
                    child: activeUser?.photoURL == null 
                      ? Icon(Icons.person, color: colorScheme.primary) 
                      : null,
                  );
                }
              ),
            ),
          ),
        ],
      ),
      
      body: _pages[_selectedIndex], 

      // --- BOTTOM NAVIGATION BAR KUSTOM (RATA BAWAH) ---
      bottomNavigationBar: Container(
        height: 80, // Tinggi navbar disesuaikan agar pas di dalam row
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Menu Beranda (Kiri)
            Expanded(
              child: _buildNavButton(
                icon: Icons.home, 
                label: 'Beranda', 
                index: 0, 
                colorScheme: colorScheme,
              ),
            ),
            
            // Tombol Inspeksi Tengah (Rata di dalam row, tetap berbentuk lingkaran)
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 56, 
                  height: 56,
                  child: Material(
                    color: _selectedIndex == 1 ? colorScheme.primary : colorScheme.primaryContainer,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = 1),
                      child: Icon(
                        Icons.document_scanner, 
                        color: _selectedIndex == 1 ? colorScheme.onPrimary : colorScheme.onPrimaryContainer, 
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Menu Profil (Kanan)
            Expanded(
              child: _buildNavButton(
                icon: Icons.person, 
                label: 'Profil', 
                index: 2, 
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required String label, required int index, required ColorScheme colorScheme}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28), 
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// =========================================================
// WIDGET BERANDA (HOME VIEW)
// =========================================================
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    
    final String currentDate = DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // Salam
        Text(currentDate, style: TextStyle(color: colorScheme.secondary, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),

        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            final activeUser = snapshot.data ?? user;
            final firstName = activeUser?.displayName?.split(' ').first ?? 'Pengendara';
            return Text('Halo, $firstName', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary));
          }
        ),

        Text('Siap untuk inspeksi hari ini?', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.primaryContainer,
            image: DecorationImage(
              image: const AssetImage('assets/images/hero.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(colorScheme.primaryContainer.withOpacity(0.85), BlendMode.srcATop),
            ),
            boxShadow: [
              BoxShadow(color: colorScheme.primaryContainer.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: colorScheme.onPrimaryContainer, size: 20),
                        const SizedBox(width: 8),
                        Text('AI FEATURE', style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Teknologi Computer Vision Presisi Tinggi', 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 8),
                    Text('AI kami menganalisis ribuan titik data secara instan untuk mendeteksi kerusakan eksterior dengan akurasi maksimal.', 
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, letterSpacing: -0.15)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              Material(
                color: Colors.transparent,
                child: Ink(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.onPrimaryContainer.withOpacity(0.5), width: 2),
                    color: colorScheme.onPrimaryContainer.withOpacity(0.2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30), // Memastikan efek klik melingkar
                    splashColor: colorScheme.onPrimaryContainer.withOpacity(0.6), // Warna cipratan saat diklik
                    highlightColor: colorScheme.onPrimaryContainer.withOpacity(0.4), // Warna redup saat ditahan
                    onTap: () {
                      final parent = context.findAncestorStateOfType<_DashboardScreenState>();
                      parent?.setState(() {
                        parent._selectedIndex = 1; // Pindah ke menu Inspeksi
                      });
                    },
                    child: Icon(Icons.center_focus_strong, color: colorScheme.onPrimaryContainer, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- BAGIAN RIWAYAT (LAPORAN TERAKHIR) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Laporan Terakhir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              },
              child: Text('Lihat Semua', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // STREAM REAL TIME DARI DATABASE
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseService().streamInspections(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3))),
                child: const Center(child: Text('Belum ada inspeksi kendaraan.', style: TextStyle(fontWeight: FontWeight.w500))),
              );
            }

            // Ambil hanya 1 dokumen terbaru
            final docs = snapshot.data!.docs.take(3).toList();

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final String reportId = doc.id;
                final String vehicleName = data['vehicleName'] ?? 'Kendaraan';
                final String plateNumber = data['plateNumber'] ?? '-';
                final String status = data['status'] ?? 'Sangat Baik';
                final List<dynamic> localPaths = data['localImagePaths'] ?? [];
                final String localThumb =
                    localPaths.isNotEmpty ? localPaths[0].toString() : '';

                Color statusColor = Colors.green;
                if (status == 'Butuh Perbaikan Segera') {
                  statusColor = Colors.red;
                }
                if (status == 'Minor / Perhatian') {
                  statusColor = Colors.orange;
                }

                String timeDisplay = 'Baru saja';
                if (data['timestamp'] != null) {
                  timeDisplay = DateFormat(
                    'd MMM, HH:mm',
                    'id_ID',
                  ).format((data['timestamp'] as Timestamp).toDate());
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryDetailScreen(
                          reportId: reportId,
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  localThumb.isNotEmpty
                                      ? Image.file(
                                          File(localThumb),
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stk) => Container(
                                            color: colorScheme.surfaceContainerHighest,
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        )
                                      : Container(
                                          color: colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.directions_car),
                                        ),

                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            status.toUpperCase() == 'SANGAT BAIK'
                                                ? 'AMAN'
                                                : 'ISSUES',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      vehicleName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.primary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Plat: $plateNumber\n$timeDisplay',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 100), // Ruang bawah ekstra
      ],
    );
  }

  Widget _buildFindingChip(String label, Color bgColor, Color textColor, {bool isError = false, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: Text(
        label, 
        style: TextStyle(color: textColor, fontSize: 12, fontFamily: 'Courier', fontWeight: isError ? FontWeight.bold : FontWeight.w600),
      ),
    );
  }
}