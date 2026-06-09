import 'package:flutter/material.dart';
import 'package:lecetdikit/services/auth_service.dart';
import 'package:lecetdikit/main.dart'; // Import main.dart untuk akses themeNotifier

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

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
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await _authService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFba1a1a), 
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
    final user = _authService.currentUser;
    final String displayName = user?.displayName ?? 'Pengguna Tamu';
    final String displayEmail = user?.email ?? 'Tidak ada email tertaut';
    final String initialName = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    // Mengambil skema warna dari tema saat ini (Otomatis menyesuaikan Light/Dark)
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      
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
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1), width: 4),
                  ),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null 
                        ? Text(initialName, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorScheme.primary))
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- NAMA & BADGE ---
            Text(
              displayName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            
            const SizedBox(height: 48),

            // --- GRUP DETAIL AKUN ---
            _buildGlassCard(
              colorScheme: colorScheme,
              child: Column(
                children: [
                  _buildListTile(icon: Icons.person, title: 'Detail Akun', isHeader: true, colorScheme: colorScheme),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _buildDetailRow('Email', displayEmail, colorScheme),
                  _buildDetailRow('Status', user?.isAnonymous == true ? 'Mode Tamu' : 'Terverifikasi', colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- GRUP PENGATURAN (TEMA DINAMIS) ---
            _buildGlassCard(
              colorScheme: colorScheme,
              child: Column(
                children: [
                  _buildListTile(icon: Icons.settings, title: 'Pengaturan', isHeader: true, colorScheme: colorScheme),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tema Aplikasi', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: colorScheme.onSurface)),
                              Text('Pilih tampilan antarmuka', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                        ),
                        
                        // Dropdown Pilihan Tema
                        DropdownButton<ThemeMode>(
                          value: themeNotifier.value,
                          dropdownColor: colorScheme.surface,
                          underline: const SizedBox(), // Menghilangkan garis bawah
                          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                          style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500),
                          onChanged: (ThemeMode? newMode) {
                            if (newMode != null) {
                              setState(() {
                                themeNotifier.value = newMode; // Ubah global tema seketika
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: ThemeMode.system, child: Text('Tema Sistem')),
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
                          ],
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
              colorScheme: colorScheme,
              child: _buildListTile(icon: Icons.info_outline, title: 'Tentang Aplikasi', trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant), colorScheme: colorScheme),
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
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Text('AutoVision AI v2.4.0 • Building Trust in Automotive', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BANTUAN UI DINAMIS --- //
  Widget _buildGlassCard({required Widget child, required ColorScheme colorScheme}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildListTile({required IconData icon, required String title, Widget? trailing, bool isHeader = false, required ColorScheme colorScheme}) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, fontSize: 15, color: colorScheme.onSurface)),
      trailing: trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}