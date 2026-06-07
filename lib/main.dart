import 'package:flutter/material.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      
      // Langsung menuju Beranda
      home: const DashboardScreen(), 
    );
  }
}