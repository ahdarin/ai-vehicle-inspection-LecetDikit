import 'package:flutter/material.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/screens/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lecetdikit/services/auth_service.dart';
import 'firebase_options.dart';
import 'package:lecetdikit/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = AuthService();
  await authService.init();

  final aiService = AiService();
  await aiService.loadModel();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    const seedColor = Color(0xFF131B2E);
    
    return MaterialApp(
      title: 'LecetDikit',
      debugShowCheckedModeBanner: false,
      // Mengikuti pengaturan tema sistem HP (Light/Dark)
      themeMode: ThemeMode.system, 
      
      // -- TEMA TERANG (LIGHT MODE) --
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
          surface: const Color(0xFFFCF8FA),
          primary: const Color(0xFF000000),
          primaryContainer: const Color(0xFF131B2E),
          onPrimaryContainer: const Color(0xFFDAE2FD),
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Jika Anda mengimpor font Inter di pubspec
      ),

      // -- TEMA GELAP (DARK MODE) --
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          primary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFF1E293B),
          onPrimaryContainer: const Color(0xFFDAE2FD),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Selama masih loading koneksi ke Firebase Auth
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0c1324), // Sesuai warna background login Anda
              body: Center(child: CircularProgressIndicator(color: Color(0xFF38bdf8))),
            );
          }
          
          // Jika ada data sesi (User sudah pernah login)
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          
          // Jika tidak ada sesi (Belum login)
          return const LoginScreen();
        },
      ), 
    );
  }
}