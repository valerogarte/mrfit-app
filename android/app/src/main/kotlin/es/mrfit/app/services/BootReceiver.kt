package es.mrfit.app.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

// Receptor que se ejecuta al reiniciar el dispositivo para
// volver a activar el conteo de pasos si el usuario lo tenía habilitado.
// Por restricciones de Android 12+ (API 31), no se puede iniciar un servicio en foreground desde un BroadcastReceiver.
// Se recomienda informar al usuario para que abra la app y así reactivar el servicio.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences("step_counter_prefs", Context.MODE_PRIVATE)
            val shouldStart = prefs.getBoolean("serviceActive", false)
            Log.d("BootReceiver", "Boot completed; serviceActive=$shouldStart")
            if (shouldStart) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    // Android 12+ (API 31): No está permitido iniciar servicios foreground aquí.
                    // Se recomienda notificar al usuario para que abra la app manualmente.
                    Log.w("BootReceiver", "No se puede iniciar el servicio en foreground tras el boot en Android 12+. Solicite al usuario abrir la app.")
                    // Aquí podrías mostrar una notificación persistente invitando al usuario a abrir la app.
                    // Ejemplo: NotificationHelper.showBootNotification(context)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // Android 8-11: permitido iniciar foreground service desde el receiver.
                    val serviceIntent = Intent(context, BackgroundStepCounterService::class.java).apply {
                        action = BackgroundStepCounterService.ACTION_START_COUNTING
                    }
                    context.startForegroundService(serviceIntent)
                } else {
                    // Android <8: iniciar servicio normalmente.
                    val serviceIntent = Intent(context, BackgroundStepCounterService::class.java).apply {
                        action = BackgroundStepCounterService.ACTION_START_COUNTING
                    }
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
