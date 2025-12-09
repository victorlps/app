import 'package:flutter/material.dart';
import 'package:avisa_la/core/services/alarm_service.dart';
import 'package:avisa_la/logger.dart';

/// Tela de alarme full-screen (overlay sobre tudo)
/// Bloqueia interação até usuário confirmar
class AlarmScreen extends StatefulWidget {
  final String destinationName;
  final double distanceMeters;

  const AlarmScreen({
    super.key,
    required this.destinationName,
    required this.distanceMeters,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    Log.alarm('🚨 [ALARM SCREEN] Iniciando AlarmScreen');
    Log.alarm('   📍 Destino: ${widget.destinationName}');
    Log.alarm('   📏 Distância: ${widget.distanceMeters.round()}m');

    // Animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar alarme
    Log.alarm('🔊 Iniciando som/vibração do alarme');
    AlarmService.startAlarm();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // CRÍTICO: Garantir que alarme pare ao fechar tela
    AlarmService.stopAlarm();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    Log.alarm('⏹️ [ALARM SCREEN] Parando alarme');
    // Parar alarme
    await AlarmService.stopAlarm();

    // Fechar tela
    if (mounted) {
      Log.alarm('🔙 Fechando AlarmScreen');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Log.alarm('🏗️ Construindo AlarmScreen');
    return PopScope(
      // Impedir fechar com botão voltar
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.orange.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                
                // Ícone animado
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      size: 80,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  'Você está chegando!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Destino
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.place,
                          size: 40,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.destinationName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.distanceMeters.round()}m de distância',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Texto de instrução
                Text(
                  'Prepare-se para descer!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),

                // Botão único: Parar Alarme
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _stopAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.alarm_off, size: 32),
                        SizedBox(width: 16),
                        Text(
                          'PARAR ALARME',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
