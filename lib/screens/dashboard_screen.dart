import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lecetdikit/screens/history_screen.dart';
import 'package:lecetdikit/screens/inspection_screen.dart';
import 'package:lecetdikit/screens/profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.car_crash, color: colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 12),
            Text(
              'AutoVision AI',
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
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                child: currentUser?.photoURL == null 
                  ? Icon(Icons.person, color: colorScheme.primary) 
                  : null,
              ),
            ),
          ),
        ],
      ),
      
      body: _pages[_selectedIndex], 

      // --- TOMBOL INSPEKSI (FAB) ---
      floatingActionButton: SizedBox(
        height: 64, 
        width: 64,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: colorScheme.primaryContainer,
          elevation: 6,
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
          child: Icon(Icons.document_scanner, color: colorScheme.onPrimaryContainer, size: 30),
        ),
      ),
      // Posisi FAB agak diturunkan
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0, 
        color: colorScheme.surface,
        elevation: 10,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 65, 
          child: Row(
            children: [
              // Menggunakan Expanded agar tidak Overflow
              Expanded(
                child: _buildNavButton(
                  icon: Icons.home, 
                  label: 'Beranda', 
                  index: 0, 
                  colorScheme: colorScheme,
                ),
              ),
              
              const SizedBox(width: 64), // Ruang di tengah untuk FAB
              
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
    final firstName = user?.displayName?.split(' ').first ?? 'Pengendara';
    
    final String currentDate = DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // Salam
        Text(currentDate, style: TextStyle(color: colorScheme.secondary, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Halo, $firstName', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary)),
        Text('Siap untuk inspeksi hari ini?', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.primaryContainer,
            image: DecorationImage(
              image: const NetworkImage('https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&q=80&w=1200'),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
              child: Text('Lihat Semua', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- KARTU RIWAYAT (Desain Vertikal: Foto di atas) ---
        Container(
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
                    Image.network(
                      'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?q=80&w=600&auto=format&fit=crop', 
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF006A60).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF006A60), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('AMAN', style: TextStyle(color: Color(0xFF006A60), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Detail Informasi Laporan (Di Bagian Bawah)
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
                          child: Text(
                            'Honda Civic RS 2023', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary), 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('ID: 88A-92', style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Plat: B 1234 XYZ • 15 Menit yang lalu', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    
                    // Chips Temuan
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildFindingChip('Eksterior Lulus', colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
                        _buildFindingChip('Interior Lulus', colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
                        _buildFindingChip('Goresan Halus Bumper', colorScheme.errorContainer.withOpacity(0.5), colorScheme.error, isError: true, borderColor: colorScheme.error.withOpacity(0.3)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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