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

  bool _isLogin = true; // Status penentu: true = Login, false = Registrasi
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        // --- PROSES LOGIN EKSPLISIT ---
        await _authService.signInWithEmailPassword(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil masuk ke dashboard!')),
          );
        }
      } else {
        // --- PROSES REGISTRASI EKSPLISIT ---
        await _authService.registerWithEmailPassword(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun baru berhasil didaftarkan!')),
          );
          // Setelah berhasil daftar, otomatis switch ke halaman login
          setState(() {
            _isLogin = true;
            _passwordController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan';
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Email belum terdaftar.';
        } else if (e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
          errorMessage = 'Kata sandi salah.';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Email sudah digunakan oleh akun lain.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Kata sandi terlalu lemah (minimal 6 karakter).';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      // Jika user tidak membatalkan pop-up Google
      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil masuk dengan Google!')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masuk sebagai Tamu.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal masuk mode Tamu.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0c1324);
    const primaryContainer = Color(0xFF38bdf8);
    const outlineColor = Color(0xFF3e484f);
    const surfaceContainer = Color(0xFF191f31);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient Dekoratif (Glowing Orb)
          Positioned(
            top: -100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryContainer.withOpacity(0.1))),
            ),
          ),
          Positioned(
            bottom: -100, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8ed5ff).withOpacity(0.05))),
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
                      decoration: BoxDecoration(color: primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryContainer.withOpacity(0.2))),
                      child: const Icon(Icons.precision_manufacturing, color: primaryContainer, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text('LecetDikit AI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1)),
                    const SizedBox(height: 8),
                    const Text('Sistem inspeksi otomotif berbasis AI dengan\npresisi tinggi untuk kendaraan Anda.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 32),

                    // Glass Panel Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: surfaceContainer.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: outlineColor.withOpacity(0.5))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Judul Form Dinamis
                              Text(
                                _isLogin ? 'Masuk Akun' : 'Daftar Baru',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                                  if (!value.contains('@')) return 'Format email salah';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.mail, color: Colors.white54),
                                  hintText: 'nama@perusahaan.com',
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  filled: true,
                                  fillColor: const Color(0xFF070d1f),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: outlineColor.withOpacity(0.5))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryContainer)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Password Field
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kata Sandi', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                  if (_isLogin)
                                    GestureDetector(child: const Text('Lupa Password?', style: TextStyle(color: primaryContainer, fontSize: 12))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Kata sandi tidak boleh kosong';
                                  if (value.length < 6) return 'Minimal 6 karakter';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  filled: true,
                                  fillColor: const Color(0xFF070d1f),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: outlineColor.withOpacity(0.5))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryContainer)),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // CTA Button Utama
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryContainer,
                                    foregroundColor: const Color(0xFF004965),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 5,
                                  ),
                                  child: _isLoading 
                                    ? const CircularProgressIndicator(color: Color(0xFF004965))
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

                              // Bagian Pengubah Mode (Login / Daftar)
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
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: _isLogin ? 'Daftar Sekarang' : 'Silakan Masuk',
                                          style: const TextStyle(color: primaryContainer, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // --- DIVIDER ATAU ---
                              Row(
                                children: [
                                  Expanded(child: Divider(color: outlineColor.withOpacity(0.5))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Atau', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ),
                                  Expanded(child: Divider(color: outlineColor.withOpacity(0.5))),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // --- TOMBOL GOOGLE & TAMU (HORIZONTAL) ---
                              Row(
                                children: [
                                  // Tombol Google
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading ? null : _handleGoogleLogin,
                                      // Menggunakan icon standar agar ringan
                                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28), 
                                      label: const Text('Google', style: TextStyle(color: Colors.white)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: outlineColor.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: surfaceContainer.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Tombol Tamu
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading ? null : _handleGuestLogin,
                                      icon: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                                      label: const Text('Tamu', style: TextStyle(color: Colors.white)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: outlineColor.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: surfaceContainer.withOpacity(0.5),
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