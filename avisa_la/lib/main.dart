import 'package:flutter/material.dart';
import 'package:avisa_la/core/services/background_service.dart';
import 'package:avisa_la/core/services/notification_service.dart';
import 'package:avisa_la/core/services/permission_service.dart';
import 'package:avisa_la/core/utils/build_tracker.dart';
import 'package:avisa_la/features/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar serviços
  await NotificationService.initialize();
  await BackgroundService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // O método reassemble é chamado SEMPRE que ocorre um Hot Reload
  @override
  void reassemble() {
    super.reassemble();
    // Atualiza o timestamp automaticamente
    BuildTracker.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avisa Lá',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Card theme removed to maintain compatibility with current SDK
        // Custom card theming can be re-added if using the correct
        // `CardThemeData` type for the project's Flutter SDK.
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Aguardar um momento para splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Solicitar permissões básicas (Fase 1)
    final hasPermissions = await PermissionService.requestPhase1Permissions();

    if (!hasPermissions) {
      // Mostrar diálogo explicativo se permissões foram negadas
      if (mounted) {
        await PermissionService.showPermissionDeniedDialog(
          context,
          message:
              'O Avisa Lá precisa de permissões de localização e notificações para funcionar corretamente.',
        );
      }
    }

    // Navegar para tela principal
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'Avisa Lá',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seu alarme de destino inteligente',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromRGBO(255, 255, 255, 0.9),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
