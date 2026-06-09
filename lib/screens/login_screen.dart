import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lecetdikit/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true; 
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await _authService.signInWithEmailPassword(email, password);
      } else {
        await _authService.registerWithEmailPassword(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun baru berhasil didaftarkan!')));
          setState(() {
            _isLogin = true;
            _passwordController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan';
        if (e.toString().contains('user-not-found')) errorMessage = 'Email belum terdaftar.';
        else if (e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) errorMessage = 'Kata sandi salah.';
        else if (e.toString().contains('email-already-in-use')) errorMessage = 'Email sudah digunakan oleh akun lain.';
        else if (e.toString().contains('weak-password')) errorMessage = 'Kata sandi minimal 6 karakter.';
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal login Google. Coba lagi.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInAnonymously();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal masuk mode Tamu.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Membaca skema warna sesuai tema aktif
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background Gradient Dekoratif (Glowing Orb)
          Positioned(
            top: -100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primaryContainer.withOpacity(0.1))),
            ),
          ),
          Positioned(
            bottom: -100, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary.withOpacity(0.05))),
            ),
          ),

          // Konten Form Utama
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero Identity
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.primaryContainer.withOpacity(0.2))),
                      child: Icon(Icons.precision_manufacturing, color: colorScheme.primary, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text('LecetDikit', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.primary, letterSpacing: -1)),
                    const SizedBox(height: 8),
                    Text('Sistem inspeksi otomotif berbasis AI dengan\npresisi tinggi untuk kendaraan Anda.', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                    const SizedBox(height: 32),

                    // Glass Panel Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLogin ? 'Masuk Akun' : 'Daftar Baru',
                                style: TextStyle(color: colorScheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),

                              Text('Email', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                style: TextStyle(color: colorScheme.onSurface),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                                  if (!value.contains('@')) return 'Format email salah';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.mail, color: colorScheme.onSurfaceVariant),
                                  hintText: 'nama@perusahaan.com',
                                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primaryContainer)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Kata Sandi', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                                  if (_isLogin)
                                    GestureDetector(child: Text('Lupa Password?', style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: colorScheme.onSurface),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Kata sandi tidak boleh kosong';
                                  if (value.length < 6) return 'Minimal 6 karakter';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock, color: colorScheme.onSurfaceVariant),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  hintText: '••••••••',
                                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primaryContainer)),
                                ),
                              ),
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primaryContainer,
                                    foregroundColor: colorScheme.onPrimaryContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 5,
                                  ),
                                  child: _isLoading 
                                    ? CircularProgressIndicator(color: colorScheme.onPrimaryContainer)
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(_isLogin ? 'Masuk ke Dashboard' : 'Daftar Akun Baru', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward),
                                        ],
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _formKey.currentState?.reset();
                                      _emailController.clear();
                                      _passwordController.clear();
                                    });
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: _isLogin ? 'Belum memiliki akun? ' : 'Sudah memiliki akun? ',
                                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: _isLogin ? 'Daftar Sekarang' : 'Silakan Masuk',
                                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              Row(
                                children: [
                                  Expanded(child: Divider(color: colorScheme.outlineVariant.withOpacity(0.5))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Atau', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                  ),
                                  Expanded(child: Divider(color: colorScheme.outlineVariant.withOpacity(0.5))),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading ? null : _handleGoogleLogin,
                                      icon: Icon(Icons.g_mobiledata, color: colorScheme.primary, size: 28), 
                                      label: Text('Google', style: TextStyle(color: colorScheme.primary)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: colorScheme.surface.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading ? null : _handleGuestLogin,
                                      icon: Icon(Icons.person_outline, color: colorScheme.primary, size: 20),
                                      label: Text('Tamu', style: TextStyle(color: colorScheme.primary)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: colorScheme.surface.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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