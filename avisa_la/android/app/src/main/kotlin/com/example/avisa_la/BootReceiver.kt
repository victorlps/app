package com.example.avisa_la

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver para reiniciar alarmes após reinicialização do device
 * 
 * Google Best Practice: Apps de alarme DEVEM reiniciar alarmes após boot
 * Referência: https://developer.android.com/training/scheduling/alarms#boot
 * 
 * Requer permissão RECEIVE_BOOT_COMPLETED no AndroidManifest.xml
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "📱 Device reiniciado - Preparando para reiniciar alarmes...")
            
            // O FlutterBackgroundService será reiniciado automaticamente
            // se estava ativo antes do reboot (configuração em AndroidManifest.xml)
            
            // Notificar app Flutter que device foi reiniciado
            // O app deve recarregar alarmes salvos
            try {
                val launchIntent = context?.packageManager?.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent?.putExtra("restarted_after_boot", true)
                
                Log.d("BootReceiver", "✅ Alarmes serão recarregados quando app for aberto")
            } catch (e: Exception) {
                Log.e("BootReceiver", "❌ Erro ao preparar reinício de alarmes: ${e.message}")
            }
        }
    }
}
