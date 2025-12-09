package com.example.avisa_la

import android.os.Bundle
import android.view.WindowManager
import android.content.Intent
import android.app.ActivityManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.avisa_la/alarm"
    private val NOTIFICATION_CHANNEL = "alarm_fullscreen_channel"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Permitir que alarmes acordem o device e mostrem sobre lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        
        // Verificar se foi aberto por intent de alarme
        handleAlarmIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleAlarmIntent(intent)
    }
    
    private fun handleAlarmIntent(intent: Intent?) {
        if (intent?.action == "ALARM_FULL_SCREEN_ACTION") {
            // Log para debug
            android.util.Log.d("MainActivity", "🔔 App aberto via fullScreenIntent!")
            
            // Trazer app para frente
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Android 12+: Verifica se app pode agendar alarmes exatos
                "canScheduleExactAlarms" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                            val canSchedule = alarmManager.canScheduleExactAlarms()
                            android.util.Log.d("MainActivity", "✅ canScheduleExactAlarms: $canSchedule")
                            result.success(canSchedule)
                        } else {
                            // Android < 12 não precisa desta permissão
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Erro ao verificar SCHEDULE_EXACT_ALARM", e)
                        result.success(false)
                    }
                }
                // Abre configurações do sistema para permitir alarmes exatos
                "openAlarmPermissionSettings" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                            val intent = Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Erro ao abrir configurações", e)
                        result.success(false)
                    }
                }
                "bringToFront" -> {
                    try {
                        // Tentar mover tarefa existente para frente
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        am.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)

                        // Fallback: iniciar activity com flags fortes
                        val intent = Intent(this, MainActivity::class.java).apply {
                            action = Intent.ACTION_MAIN
                            addCategory(Intent.CATEGORY_LAUNCHER)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Erro ao bringToFront", e)
                        result.success(false)
                    }
                }
                "showFullScreenAlarm" -> {
                    try {
                        val destination = call.argument<String>("destination") ?: "Destino"
                        val distance = call.argument<Double>("distance") ?: 0.0
                        
                        android.util.Log.d("MainActivity", "🔔 [NATIVE] Iniciando alarme full-screen para: $destination")
                        
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        
                        // Android 12+: Verificar se pode usar fullScreenIntent
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val canUseFullScreen = notificationManager.canUseFullScreenIntent()
                            android.util.Log.d("MainActivity", "📱 canUseFullScreenIntent: $canUseFullScreen")
                            
                            if (!canUseFullScreen) {
                                android.util.Log.e("MainActivity", "⚠️ Sem permissão fullScreenIntent! Abrindo app via Intent")
                                // Fallback: abrir app diretamente
                                val openIntent = Intent(this, MainActivity::class.java).apply {
                                    action = "ALARM_FULL_SCREEN_ACTION"
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                                }
                                startActivity(openIntent)
                            }
                        }
                        
                        // Criar Intent para fullScreenIntent que ABRE o app
                        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
                            action = "ALARM_FULL_SCREEN_ACTION"
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                            putExtra("destination", destination)
                            putExtra("distance", distance)
                        }
                        
                        val fullScreenPendingIntent = PendingIntent.getActivity(
                            this,
                            999,
                            fullScreenIntent,
                            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                        )
                        
                        // Criar notificação com CATEGORY_ALARM
                        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
                            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                            .setContentTitle("🚨 ALARME - $destination")
                            .setContentText("Você está a ${String.format("%.0f", distance)}m do destino!")
                            .setPriority(NotificationCompat.PRIORITY_MAX)
                            .setCategory(NotificationCompat.CATEGORY_ALARM)
                            .setFullScreenIntent(fullScreenPendingIntent, true)
                            .setAutoCancel(false)
                            .setOngoing(true)
                            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                            .setContentIntent(fullScreenPendingIntent)
                            .build()
                        
                        // CRÍTICO: Adicionar flags no Notification
                        notification.flags = notification.flags or 
                            android.app.Notification.FLAG_INSISTENT or
                            android.app.Notification.FLAG_NO_CLEAR
                        
                        notificationManager.notify(999, notification)
                        android.util.Log.d("MainActivity", "✅ [NATIVE] Notificação full-screen criada!")
                        
                        // FORÇAR abertura do app IMEDIATAMENTE (Android 12+ bypass)
                        // Isto funciona porque o código está executando do background service
                        android.util.Log.d("MainActivity", "🚀 [NATIVE] Forçando abertura do app...")
                        startActivity(fullScreenIntent)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "❌ [NATIVE] Erro ao criar alarme: ${e.message}", e)
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    /// Notificacao nativa removida - usar NotificationService do Flutter
    /// A logica de notificacao esta em lib/core/services/notification_service.dart
}


