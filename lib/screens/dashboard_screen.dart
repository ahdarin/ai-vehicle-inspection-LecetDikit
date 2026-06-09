import 'package:flutter/material.dart';
import 'package:lecetdikit/screens/inspection_screen.dart';
import 'package:lecetdikit/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan dirender berdasarkan menu yang diklik
  final List<Widget> _pages = [
    const HomeView(),             // Index 0: Beranda
    const InspectionScreen(),     // Index 1: Halaman Inspeksi Baru
    const Center(child: Text('Riwayat Pengembangan')), // Index 2
    const ProfileScreen(),  // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(Icons.account_circle, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Text('LecetDikit', 
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      // Konten otomatis berubah sesuai index
      body: _pages[_selectedIndex], 
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.document_scanner), label: 'Inspeksi'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// Widget Terpisah khusus untuk Tampilan Beranda
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        Text('Selasa, 24 Okt', style: TextStyle(color: colorScheme.secondary, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Halo, Budi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary)),
        Text('Siap untuk inspeksi hari ini?', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        // Hero Card
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
      ],
    );
  }
}