import 'package:avisa_la/core/services/background_service.dart';
import 'package:avisa_la/core/services/notification_service.dart';
import 'package:avisa_la/core/services/permission_service.dart';
import 'package:avisa_la/core/utils/build_tracker.dart';
import 'package:avisa_la/core/utils/app_launcher.dart';
import 'package:avisa_la/features/alarm/alarm_screen.dart';
import 'package:avisa_la/features/home/home_page.dart';
import 'package:avisa_la/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Log.alarm('📱 Avisa Lá - Iniciando aplicação');

  // Inicializar serviços
  Log.alarm('🔧 Inicializando NotificationService...');
  await NotificationService.initialize();
  
  Log.alarm('🔧 Inicializando BackgroundService...');
  await BackgroundService.initialize();

  // Capturar dados de lançamento via notificação (cold start)
  Log.alarm('🔍 Verificando se app foi aberto por notificação...');
  final launchAlarmData = await NotificationService.getLaunchAlarmData();

  Log.alarm('✅ App pronto para executar');
  runApp(MyApp(initialAlarmData: launchAlarmData));
}

class MyApp extends StatefulWidget {
  final AlarmLaunchData? initialAlarmData;
  const MyApp({super.key, this.initialAlarmData});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAlarmScreenOpen = false;

  @override
  void initState() {
    super.initState();
    // ✅ CRÍTICO: Configurar listener DEPOIS que widget tree existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBackgroundServiceListener();
    });
  }

  /// Escuta eventos do background service para abrir tela de alarme
  void _setupBackgroundServiceListener() {
    Log.alarm('🎧 Configurando listener para eventos de alarme...');
    FlutterBackgroundService().on('showAlarm').listen((event) async {
      Log.alarm('📢 Evento showAlarm recebido: $event');
      
      await _navigateToAlarmScreen(event);
    });
    Log.alarm('✅ Listener configurado com sucesso');
  }

  /// Navega para AlarmScreen de forma segura com retry
  Future<void> _navigateToAlarmScreen(dynamic event) async {
    if (_isAlarmScreenOpen) {
      Log.alarm('ℹ️ AlarmScreen já está aberta, ignorando novo push');
      return;
    }

    if (event == null) {
      Log.alarm('⚠️ Evento null - não pode navegar');
      return;
    }

    final destination = event['destination'] as String? ?? 'Destino';
    final distance = event['distance'] as double? ?? 0.0;

    Log.alarm('🚀 Tentando navegar para AlarmScreen: $destination ($distance m)');

    // Tentar trazer app para frente
    await AppLauncher.bringToFront();

    final navState = navigatorKey.currentState;
    if (navState == null) {
      Log.alarm('⚠️ navigatorKey state null - app pode não estar pronto, aguardando...');
      // Tentar de novo em 500ms
      await Future.delayed(const Duration(milliseconds: 500));
      return _navigateToAlarmScreen(event);
    }

    _isAlarmScreenOpen = true;

    try {
      await navState.push(
        MaterialPageRoute(
          builder: (context) => AlarmScreen(
            destinationName: destination,
            distanceMeters: distance,
          ),
          fullscreenDialog: true,
        ),
      );
    } finally {
      _isAlarmScreenOpen = false;
    }
  }

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
      navigatorKey: navigatorKey,
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
      home: SplashScreen(initialAlarmData: widget.initialAlarmData),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final AlarmLaunchData? initialAlarmData;
  const SplashScreen({super.key, this.initialAlarmData});

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
      // Se app foi aberto por notificação de alarme, navega direto para AlarmScreen
      if (widget.initialAlarmData != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AlarmScreen(
              destinationName: widget.initialAlarmData!.destination,
              distanceMeters: widget.initialAlarmData!.distance,
            ),
            fullscreenDialog: true,
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
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
