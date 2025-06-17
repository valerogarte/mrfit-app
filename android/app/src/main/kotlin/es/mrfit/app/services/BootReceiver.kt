// android/app/src/main/kotlin/es/mrfit/app/services/BootReceiver.kt

package es.mrfit.app.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

// Receptor que se ejecuta al reiniciar el dispositivo para
// volver a activar el conteo de pasos si el usuario lo tenía habilitado.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences("step_counter_prefs", Context.MODE_PRIVATE)
            val shouldStart = prefs.getBoolean("serviceActive", false)
            Log.d("BootReceiver", "Boot completed; serviceActive=$shouldStart")
            if (shouldStart) {
                val serviceIntent = Intent(context, BackgroundStepCounterService::class.java).apply {
                    action = BackgroundStepCounterService.ACTION_START_COUNTING
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
