import 'package:flutter/material.dart';
import 'package:lecetdikit/screens/about_screen.dart';
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

  void _showEditProfileBottomSheet(BuildContext context, ColorScheme colorScheme) {
    final user = _authService.currentUser;
    final nameController = TextEditingController(text: user?.displayName);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(height: 8),
                Text('Perbarui nama tampilan akun Anda di bawah ini.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),
                Text('Nama Lengkap', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primaryContainer)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await user?.updateDisplayName(nameController.text.trim());
                        await user?.reload();
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {}); // Memperbarui UI halaman profil seketika
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final bool isGuest = user?.isAnonymous ?? true;
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
            if (!isGuest) ...[
              _buildGlassCard(
                colorScheme: colorScheme,
                child: Column(
                  children: [
                    _buildListTile(icon: Icons.person, title: 'Detail Akun', isHeader: true, colorScheme: colorScheme),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    _buildDetailRow('Email', displayEmail, colorScheme),
                    _buildDetailRow('Status', 'Terverifikasi', colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- GRUP PENGATURAN ---
            _buildGlassCard(
              colorScheme: colorScheme,
              child: Column(
                children: [
                  _buildListTile(icon: Icons.settings, title: 'Pengaturan', isHeader: true, colorScheme: colorScheme),
                  
                  // Item Menu Edit Profil Kustom
                  if (!isGuest) ...[
                    ListTile(
                      leading: Icon(Icons.edit_outlined, color: colorScheme.primary),
                      title: Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: colorScheme.onSurface)),
                      subtitle: Text('Ubah nama tampilan akun Anda', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                      onTap: () => _showEditProfileBottomSheet(context, colorScheme),
                    ),
                    Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
                  ],
                  
                  Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
                  
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
                        
                        DropdownButton<ThemeMode>(
                          value: themeNotifier.value,
                          dropdownColor: colorScheme.surface,
                          underline: const SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                          style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500),
                          onChanged: (ThemeMode? newMode) {
                            if (newMode != null) {
                              setState(() {
                                themeNotifier.value = newMode;
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
              child: _buildListTile(
                icon: Icons.info_outline, 
                title: 'Tentang Aplikasi', 
                trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant), 
                colorScheme: colorScheme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
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

  Widget _buildListTile({required IconData icon, required String title, Widget? trailing, bool isHeader = false, required ColorScheme colorScheme, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, fontSize: 15, color: colorScheme.onSurface)),
      trailing: trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
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