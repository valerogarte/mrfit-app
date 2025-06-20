// android/app/src/main/kotlin/es/mrfit/app/services/BackgroundStepCounterService.kt

package es.mrfit.app.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import es.mrfit.app.R
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.*

// Servicio en segundo plano para contar pasos utilizando el sensor de hardware.
// Se ejecuta como un servicio en primer plano para garantizar su continuidad.
class BackgroundStepCounterService : Service(), SensorEventListener {
    private lateinit var sensorManager: SensorManager
    private var stepSensor: Sensor? = null
    // Almacena el último valor de pasos reportado por el sensor.
    // Se usa para calcular el delta de pasos desde la última lectura.
    private var lastStepsValue: Float = 0f
    // Acumula los pasos detectados que aún no se han enviado a la capa de Flutter.
    private var pendingSteps: Int = 0
    // Preferencias compartidas para persistir el estado del contador entre reinicios del servicio.
    private lateinit var prefs: SharedPreferences

    // Handler y Runnable para el temporizador principal que fuerza el envío de pasos periódicamente.
    private lateinit var handler: Handler
    private lateinit var runnable: Runnable

    // Handler y Runnable para el temporizador de inactividad.
    // Si no se detectan nuevos pasos durante un tiempo, fuerza un envío.
    private lateinit var inactivityHandler: Handler
    private lateinit var inactivityRunnable: Runnable

    // Instancia del motor de Flutter para comunicarse con el código Dart.
    private var flutterEngine: FlutterEngine? = null
    // Canal de comunicación para enviar datos (pasos) a Flutter.
    private lateinit var channel: MethodChannel

    // Indica si los listeners del sensor y los temporizadores están activos.
    private var isCountingActive = false

    companion object {
        // Etiqueta para logging, facilita la depuración.
        private const val TAG = "BackgroundStepCounter"
        // Nombre del archivo de SharedPreferences donde se guardan los datos del contador.
        private const val PREFS_NAME = "step_counter_prefs"
        // Clave para guardar/recuperar el último valor de pasos del sensor en SharedPreferences.
        private const val KEY_LAST_STEPS = "lastStepsValue"
        // Clave para guardar/recuperar los pasos pendientes en SharedPreferences.
        private const val KEY_PENDING_STEPS = "pendingSteps"
        // Clave para recordar si el servicio debe estar activo (útil tras reinicios del dispositivo).
        private const val KEY_SERVICE_ACTIVE = "serviceActive"
        // Intervalo para el envío periódico de pasos (ej. cada minuto).
        private const val FLUSH_INTERVAL_MS = 60_000L
        // Tiempo de espera sin nuevos pasos antes de forzar un envío (ej. 15 segundos).
        private const val INACTIVITY_FLUSH_DELAY_MS = 15_000L

        // Constantes para la notificación del servicio en primer plano.
        private const val NOTIFICATION_ID = 12345
        private const val NOTIFICATION_CHANNEL_ID = "StepCounterChannel"


        // Acciones de Intent para controlar el servicio desde otras partes de la aplicación (ej. Flutter).
        const val ACTION_START_COUNTING = "es.mrfit.app.services.action.START_COUNTING"
        const val ACTION_STOP_COUNTING = "es.mrfit.app.services.action.STOP_COUNTING"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Servicio onCreate: Inicializando componentes.")

        createNotificationChannel() // Esencial para Android Oreo (API 26) y superior.

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // Carga el estado previo del contador desde SharedPreferences.
        lastStepsValue = prefs.getFloat(KEY_LAST_STEPS, 0f)
        pendingSteps = prefs.getInt(KEY_PENDING_STEPS, 0)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        // Inicializa FlutterEngine para la comunicación con Dart.
        // Este motor es específico para este servicio y se destruye con él.
        flutterEngine = FlutterEngine(this.applicationContext)
        flutterEngine!!.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "background_step_counter")

        handler = Handler(Looper.getMainLooper())
        runnable = Runnable {
            Log.d(TAG, "Temporizador principal: Enviando pasos.")
            flushSteps() // El método flushSteps se encarga de la lógica de re-programación.
        }

        inactivityHandler = Handler(Looper.getMainLooper())
        inactivityRunnable = Runnable {
            Log.d(TAG, "Temporizador de inactividad: Enviando pasos.")
            flushSteps()
        }

        // Si el servicio se reinicia (ej. por el sistema) y estaba activo, reanuda el conteo.
        if (prefs.getBoolean(KEY_SERVICE_ACTIVE, false)) {
            Log.d(TAG, "El servicio estaba marcado como activo, reiniciando conteo.")
            startCountingInternally()
        }
    }

    // Crea el canal de notificación necesario para mostrar notificaciones en Android 8.0+.
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Canal del Servicio Contador de Pasos", // Nombre visible para el usuario.
                NotificationManager.IMPORTANCE_DEFAULT // Importancia (afecta cómo se muestra).
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    // Construye y devuelve la notificación para el servicio en primer plano.
    // Esta notificación es visible para el usuario mientras el servicio está activo.
    private fun getNotification(): Notification {
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Contador de Pasos Activo")
            .setContentText("Contando tus pasos en segundo plano.")
            .setSmallIcon(R.mipmap.ic_launcher) // Icono de la notificación.
            .setOngoing(true) // Hace que la notificación no se pueda descartar fácilmente por el usuario.
            .build()
    }

    // Configura el manejador para llamadas de métodos desde Dart hacia este servicio.
    // Actualmente, es mínimo o no se usa si el control principal es mediante Intents.
    private fun setupMethodChannelHandler() {
        channel.setMethodCallHandler { call, result ->
            Log.d(TAG, "Llamada de método recibida en el canal del servicio: ${call.method} - Probablemente inesperado para start/stop.")
            result.notImplemented()
        }
    }

    // Inicia internamente el proceso de conteo de pasos.
    // Registra el listener del sensor y activa el servicio en primer plano.
    private fun startCountingInternally() {
        if (!isCountingActive) {
            if (stepSensor != null) {
                sensorManager.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_NORMAL)
                handler.removeCallbacks(runnable)
                handler.postDelayed(runnable, FLUSH_INTERVAL_MS)
                isCountingActive = true
                Log.d(TAG, "Conteo de pasos iniciado internamente.")
            } else {
                Log.e(TAG, "Sensor de pasos no disponible. Deteniendo el servicio.")
                stopForeground(true)
                stopSelf()
            }
        } else {
            Log.d(TAG, "El conteo de pasos ya estaba activo internamente.")
        }
    }

    // Detiene internamente el proceso de conteo de pasos.
    // Desregistra el listener del sensor y realiza un último envío de pasos acumulados.
    private fun stopCountingInternally() {
        if (isCountingActive) {
            sensorManager.unregisterListener(this)
            // Marcar como inactivo ANTES de llamar a flushSteps.
            // Esto evita que flushSteps reprograme el temporizador principal.
            isCountingActive = false 
            flushSteps() // Envía los pasos pendientes acumulados antes de detener.
            Log.d(TAG, "Conteo de pasos detenido internamente.")
        }
        // La detención del servicio en primer plano (stopForeground) se maneja en onStartCommand
        // cuando se recibe ACTION_STOP_COUNTING, para asegurar que se haga en el momento adecuado.
    }

    // Método principal que se ejecuta cuando el servicio es iniciado o recibe un comando.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Servicio onStartCommand, action: ${intent?.action}")

        // Asegurarse de llamar a startForeground inmediatamente al inicio del servicio.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, getNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH or ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, getNotification())
        }

        when (intent?.action) {
            ACTION_START_COUNTING -> {
                Log.d(TAG, "ACTION_START_COUNTING recibido")
                // Persiste la intención de que el servicio esté activo.
                prefs.edit().putBoolean(KEY_SERVICE_ACTIVE, true).apply()
                startCountingInternally() // Inicia el conteo y el modo foreground.
            }
            ACTION_STOP_COUNTING -> {
                Log.d(TAG, "ACTION_STOP_COUNTING recibido")
                prefs.edit().putBoolean(KEY_SERVICE_ACTIVE, false).apply()
                stopCountingInternally() // Detiene el conteo.
                stopForeground(true) // Elimina la notificación y saca el servicio del primer plano.
                stopSelf() // Detiene el servicio completamente.
                Log.d(TAG, "Servicio detenido debido a ACTION_STOP_COUNTING")
                return START_NOT_STICKY // No reiniciar automáticamente si se detuvo explícitamente.
            }
            else -> {
                // Maneja reinicios del servicio por el sistema (cuando START_STICKY está activo).
                if (prefs.getBoolean(KEY_SERVICE_ACTIVE, false)) {
                    Log.d(TAG, "Servicio reiniciado o iniciado sin acción específica, y estaba previamente activo. Reiniciando conteo.")
                    startCountingInternally() // Asegura que el modo foreground se active si es necesario.
                } else {
                    Log.d(TAG, "Servicio iniciado sin acción específica y no estaba previamente activo. Deteniendo.")
                    stopForeground(true) // Asegura que no quede en primer plano si no debe estar activo.
                    stopSelf()
                    return START_NOT_STICKY // No continuar si no estaba previsto que estuviera activo.
                }
            }
        }
        // Indica al sistema que, si el servicio se cierra inesperadamente, debe intentar reiniciarlo.
        return START_STICKY
    }

    // Callback invocado cuando el sensor de pasos detecta un cambio.
    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_STEP_COUNTER) {
            val currentSteps = event.values[0] // Valor absoluto de pasos desde el último reinicio del sensor.

            // Inicialización de lastStepsValue en la primera lectura o tras un reinicio de datos.
            if (lastStepsValue == 0f && pendingSteps == 0 && !prefs.contains(KEY_LAST_STEPS)) {
                lastStepsValue = currentSteps
                prefs.edit().putFloat(KEY_LAST_STEPS, lastStepsValue).apply()
                Log.d(TAG, "Sensor inicializado por primera vez o tras borrado de datos. Pasos base: $lastStepsValue")
                return // No se cuentan estos pasos iniciales como un delta.
            } else if (lastStepsValue == 0f && prefs.contains(KEY_LAST_STEPS)) {
                // Caso donde el servicio se reinició y lastStepsValue es 0 (ej. reinicio del dispositivo y sensor reseteado),
                // o el sensor reporta 0 después de haber reportado valores no nulos.
                if (currentSteps > 0) {
                    Log.d(TAG, "Sensor reportó 0 previamente, nueva lectura $currentSteps. Tratando como nueva base.")
                    lastStepsValue = currentSteps
                    prefs.edit().putFloat(KEY_LAST_STEPS, lastStepsValue).apply()
                    return // Se establece la nueva base, no hay delta aún.
                }
                // Si currentSteps también es 0, esperar a una lectura no nula.
            }


            var delta = (currentSteps - lastStepsValue).toInt()

            if (delta < 0) {
                // Un delta negativo usualmente indica un reinicio del contador del sensor (ej. reinicio del dispositivo).
                // 'currentSteps' es el nuevo total desde el reinicio del sensor.
                // Se asume que 'currentSteps' son pasos nuevos desde que 'lastStepsValue' se volvió inválido.
                Log.w(TAG, "Reinicio del contador del sensor detectado. Anterior: $lastStepsValue, Actual: $currentSteps. Añadiendo $currentSteps a pendientes. Nueva base: $currentSteps")
                pendingSteps += currentSteps.toInt() // Añade todos los pasos actuales como nuevos.
                lastStepsValue = currentSteps      // La nueva base es la lectura actual del sensor.
            } else if (delta > 0) {
                // Delta positivo: se han detectado nuevos pasos.
                pendingSteps += delta
                lastStepsValue = currentSteps
            }
            // Si delta es 0, no hay cambio en los pasos, no hacer nada.
            
            // Guarda el estado actual en SharedPreferences para persistencia.
            prefs.edit()
                .putFloat(KEY_LAST_STEPS, lastStepsValue)
                .putInt(KEY_PENDING_STEPS, pendingSteps)
                .apply()

            if (delta != 0) { 
                 Log.d(TAG, "onSensorChanged: currentRawSensor=$currentSteps, previousSensorValueForDeltaCalculation=${lastStepsValue-delta}, delta=$delta, totalPendingSteps=$pendingSteps. Updated lastStepsValue to $lastStepsValue.")
            }

            // Si se detectaron pasos y el conteo está activo, reprograma el temporizador de inactividad.
            if (delta > 0 && isCountingActive) {
                inactivityHandler.removeCallbacks(inactivityRunnable)
                inactivityHandler.postDelayed(inactivityRunnable, INACTIVITY_FLUSH_DELAY_MS)
                Log.d(TAG, "Actividad detectada, envío por inactividad reprogramado en ${INACTIVITY_FLUSH_DELAY_MS / 1000}s.")
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No es relevante para el contador de pasos, que proporciona valores absolutos.
    }

    // Envía los pasos pendientes a Flutter y gestiona la reprogramación de los temporizadores.
    private fun flushSteps() {
        // Cancela envíos pendientes para evitar duplicados si este método es llamado
        // por diferentes temporizadores casi simultáneamente.
        handler.removeCallbacks(runnable)
        inactivityHandler.removeCallbacks(inactivityRunnable)

        if (pendingSteps > 0) {
            Log.d(TAG, "Flush: Intentando enviar $pendingSteps pasos.")
            if (flutterEngine != null) {
                // Verifica si el ejecutor Dart del FlutterEngine está activo y listo para recibir.
                if (flutterEngine!!.dartExecutor.isExecutingDart) {
                    Log.i(TAG, "✅ DartExecutor está ACTIVO. Invocando 'registerSteps' con $pendingSteps pasos.")
                    channel.invokeMethod("registerSteps", pendingSteps)
                    // Asume éxito y resetea los pasos pendientes.
                    // Una implementación más robusta podría esperar confirmación o manejar errores de envío.
                    pendingSteps = 0
                    prefs.edit().putInt(KEY_PENDING_STEPS, pendingSteps).apply()
                    Log.d(TAG, "Flush: Pasos enviados a Dart (presumiblemente), pendingSteps reseteado a 0.")
                } else {
                    Log.e(TAG, "❌ DartExecutor NO ESTÁ ACTIVO. Pasos ($pendingSteps) no enviados. Se reintentará en el próximo flush.")
                    // Los pasos permanecen en pendingSteps y SharedPreferences para el próximo intento.
                }
            } else {
                Log.e(TAG, "❌ FlutterEngine es NULL. Pasos ($pendingSteps) no enviados. Se reintentará si el motor está disponible.")
                // Los pasos permanecen guardados para un futuro envío.
            }
        } else {
            Log.d(TAG, "Flush: No hay pasos pendientes para enviar.")
        }

        // Si el conteo sigue activo, reprograma el temporizador principal.
        // Esto asegura que, incluso con actividad continua (que resetea el temporizador de inactividad),
        // ocurra un envío al menos cada FLUSH_INTERVAL_MS.
        if (isCountingActive) {
            handler.postDelayed(runnable, FLUSH_INTERVAL_MS)
            Log.d(TAG, "Flush: Temporizador principal reprogramado en ${FLUSH_INTERVAL_MS / 1000}s (servicio activo).")
        } else {
            Log.d(TAG, "Flush: Servicio no activo, temporizador principal no reprogramado.")
        }
    }

    // Método llamado cuando el servicio está a punto de ser destruido.
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Servicio onDestroy: Limpiando recursos.")

        if (isCountingActive) {
            sensorManager.unregisterListener(this)
            // Marcar como inactivo para que flushSteps (llamado abajo) no reprograme temporizadores.
            isCountingActive = false 
        }
        
        // Intenta un último envío de pasos pendientes antes de la destrucción total.
        Log.d(TAG, "onDestroy: Realizando comprobación final de flush.")
        flushSteps() 
        
        // Asegura la cancelación de todos los callbacks de los handlers para evitar fugas o ejecuciones post-destrucción.
        handler.removeCallbacksAndMessages(null)
        // Comprueba si inactivityHandler fue inicializado antes de usarlo, para evitar NullPointerException.
        if (this::inactivityHandler.isInitialized) {
            inactivityHandler.removeCallbacksAndMessages(null)
        }
        
        // Destruye la instancia de FlutterEngine para liberar sus recursos.
        flutterEngine?.destroy() 
        flutterEngine = null

        Log.d(TAG, "Servicio destruido completamente.")
    }

    // Requerido por la interfaz Service, pero no se usa para servicios iniciados (no enlazados).
    // Devuelve null ya que los clientes no se enlazan a este servicio.
    override fun onBind(intent: Intent?): IBinder? = null
}
