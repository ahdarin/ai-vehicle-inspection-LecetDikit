import 'package:flutter/material.dart';
import 'package:lecetdikit/screens/profile_setup_screen.dart';
import 'package:lecetdikit/services/ai_service.dart';
import 'package:lecetdikit/screens/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lecetdikit/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:lecetdikit/screens/login_screen.dart';

// Variabel global untuk mengatur tema dari layar manapun
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

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
    
    // ValueListenableBuilder akan membangun ulang (rebuild) aplikasi saat tema diubah
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'LecetDikit',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, 
          
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
            fontFamily: 'Inter',
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primaryContainer)),
                );
              }
              if (snapshot.hasData) {
                final user = snapshot.data;

                if (user != null && !user.isAnonymous && (user.displayName == null || user.displayName!.isEmpty)) {
                  return const ProfileSetupScreen();
                }
                return const DashboardScreen();
              }
              return const LoginScreen();
            },
          ), 
        );
      }
    );
  }
}