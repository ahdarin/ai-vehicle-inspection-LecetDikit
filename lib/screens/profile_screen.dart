import 'package:flutter/material.dart';
import 'package:lecetdikit/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isDarkMode = false; // Status untuk toggle dark mode

  // Fungsi untuk menampilkan konfirmasi sebelum logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Tutup dialog
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog
                await _authService.signOut();
                // main.dart akan otomatis mengarahkan kembali ke LoginScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFba1a1a), // Warna Error
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan data user yang sedang aktif
    final user = _authService.currentUser;
    
    // Menyiapkan teks default jika data kosong (misal login sebagai Tamu)
    final String displayName = user?.displayName ?? 'Pengguna Tamu';
    final String displayEmail = user?.email ?? 'Tidak ada email tertaut';
    final String initialName = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    // Warna dari desain Anda
    const backgroundColor = Color(0xFFfcf8fa);
    const primaryColor = Color(0xFF000000);
    const outlineVariantColor = Color(0xFFc6c6cd);
    const surfaceHighColor = Color(0xFFeae7e9);

    return Scaffold(
      backgroundColor: backgroundColor,
      // TOP APP BAR
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'LecetDikit AI', // Disesuaikan dengan nama aplikasi kita
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: primaryColor),
            onPressed: () {},
          )
        ],
      ),
      
      // MAIN CONTENT
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // --- HEADER FOTO PROFIL ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12, width: 4),
                  ),
                  child: CircleAvatar(
                    backgroundColor: surfaceHighColor,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    // Jika tidak ada foto (Login email/Tamu), tampilkan inisial huruf
                    child: user?.photoURL == null 
                        ? Text(initialName, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black54))
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: Colors.white, size: 16),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // --- NAMA & BADGE ---
            Text(
              displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131b2e), // Primary Container
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Premium Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- GRUP DETAIL AKUN ---
            _buildGlassCard(
              child: Column(
                children: [
                  _buildListTile(icon: Icons.person, title: 'Detail Akun', isHeader: true),
                  const Divider(height: 1, color: outlineVariantColor),
                  _buildDetailRow('Email', displayEmail),
                  _buildDetailRow('Status', user?.isAnonymous == true ? 'Mode Tamu' : 'Terverifikasi'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- GRUP PENGATURAN ---
            _buildGlassCard(
              child: Column(
                children: [
                  _buildListTile(icon: Icons.settings, title: 'Pengaturan', trailing: const Icon(Icons.chevron_right, color: Colors.grey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            Text('Gunakan tema gelap aplikasi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Switch(
                          value: _isDarkMode,
                          activeColor: const Color(0xFF131b2e),
                          onChanged: (value) {
                            setState(() => _isDarkMode = value);
                            // TODO: Implementasi logika tema global nanti jika dibutuhkan
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Dark Mode sedang dalam pengembangan')));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- GRUP TENTANG APLIKASI ---
            _buildGlassCard(
              child: _buildListTile(icon: Icons.info_outline, title: 'Tentang Aplikasi', trailing: const Icon(Icons.chevron_right, color: Colors.grey)),
            ),
            const SizedBox(height: 32),

            // --- TOMBOL KELUAR ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFffdad6), // Error Container
                  foregroundColor: const Color(0xFF93000a), // On Error Container
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('LecetDikit AI v2.4.0 • Building Trust in Automotive', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BANTUAN UI --- //
  
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc6c6cd).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildListTile({required IconData icon, required String title, Widget? trailing, bool isHeader = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, fontSize: 15)),
      trailing: trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}