package es.mrfit.app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import es.mrfit.app.services.BackgroundStepCounterService
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {

    private val SCREEN_CHANNEL = "es.mrfit.app/screen_state"
    private val USAGE_CHANNEL = "es.mrfit.app/usage_stats"
    private val HEALTH_CHANNEL = "es.mrfit.app/health"
    private val STEP_COUNTER_CHANNEL = "background_step_counter" // Same as in Dart and Service
    private val REQUEST_CODE = 1001
    private val REQUEST_FOREGROUND_SERVICE_PERMISSION = 2001
    private var screenStateReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        android.util.Log.d("MainActivity", "configureFlutterEngine CALLED for main UI engine.")

        // Channel for BackgroundStepCounterService control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEP_COUNTER_CHANNEL).setMethodCallHandler { call, result ->
            android.util.Log.d("MainActivity", "Method call received on STEP_COUNTER_CHANNEL: ${call.method}")
            when (call.method) {
                "startStepCounter" -> {
                    android.util.Log.d("MainActivity", "startStepCounter called from Dart, preparing to start service.")
                    val intent = Intent(this, BackgroundStepCounterService::class.java).apply {
                        action = BackgroundStepCounterService.ACTION_START_COUNTING
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success("Step counter service started or requested to start.")
                }
                "stopStepCounter" -> {
                    android.util.Log.d("MainActivity", "stopStepCounter called from Dart, preparing to stop service.")
                    val intent = Intent(this, BackgroundStepCounterService::class.java).apply {
                        action = BackgroundStepCounterService.ACTION_STOP_COUNTING
                    }
                    // The service will call stopSelf() and stopForeground()
                    // We just need to send the intent to trigger the action.
                    startService(intent)
                    result.success("Step counter service requested to stop.")
                }
                else -> {
                    android.util.Log.d("MainActivity", "Method ${call.method} not implemented on STEP_COUNTER_CHANNEL.")
                    result.notImplemented()
                }
            }
        }
        android.util.Log.d("MainActivity", "MethodChannel for STEP_COUNTER_CHANNEL ('$STEP_COUNTER_CHANNEL') SET UP in MainActivity.")

        // Canal para el API de UsageStats
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    val permissionGranted = hasUsageStatsPermission(this)
                    result.success(permissionGranted)
                }
                "openUsageStatsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                            result.success(null)
                        } else {
                            result.error("ACTIVITY_NOT_FOUND", "No se encontró la pantalla de ajustes de uso", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR_OPENING_SETTINGS", "Error al intentar abrir los ajustes: ${e.message}", null)
                    }
                }
                "getInactivitySlots" -> {
                    val day = call.argument<String>("day")
                    if (day != null) {
                        try {
                            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                            val date = sdf.parse(day)
                            val slots = getInactivitySlots(this, date!!.time)
                            result.success(slots)
                        } catch (e: Exception) {
                            result.error("PARSE_ERROR", "Error al parsear la fecha: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "El argumento 'day' es requerido", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Canal para permisos de Health Data History
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasHealthDataPermission" -> {
                    val permissionGranted = ContextCompat.checkSelfPermission(
                        this,
                        "android.permission.health.READ_HEALTH_DATA_HISTORY"
                    ) == PackageManager.PERMISSION_GRANTED
                    android.util.Log.d("HEALTH_CHANNEL", "hasHealthDataPermission: $permissionGranted")
                    result.success(permissionGranted)
                }
                "requestHealthDataPermission" -> {
                    if (ContextCompat.checkSelfPermission(
                            this,
                            "android.permission.health.READ_HEALTH_DATA_HISTORY"
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        android.util.Log.d("HEALTH_CHANNEL", "Permission already granted")
                        result.success(true)
                    } else {
                        android.util.Log.d("HEALTH_CHANNEL", "Requesting permission")
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf("android.permission.health.READ_HEALTH_DATA_HISTORY"),
                            REQUEST_CODE
                        )
                        result.success(false)
                    }
                }
                else -> {
                    android.util.Log.d("HEALTH_CHANNEL", "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // Canal para eventos de estado de pantalla (ScreenState)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    screenStateReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            when (intent?.action) {
                                Intent.ACTION_SCREEN_ON -> events?.success("SCREEN_ON")
                                Intent.ACTION_SCREEN_OFF -> events?.success("SCREEN_OFF")
                                Intent.ACTION_USER_PRESENT -> events?.success("USER_PRESENT")
                            }
                        }
                    }
                    val filter = IntentFilter().apply {
                        addAction(Intent.ACTION_SCREEN_ON)
                        addAction(Intent.ACTION_SCREEN_OFF)
                        addAction(Intent.ACTION_USER_PRESENT)
                    }
                    registerReceiver(screenStateReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(screenStateReceiver)
                }
            }
        )

        checkAndRequestForegroundServicePermission()
    }

    private fun checkAndRequestForegroundServicePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val permissions = arrayOf(
                "android.permission.FOREGROUND_SERVICE_DATA_SYNC"
            )
            val missingPermissions = permissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }

            if (missingPermissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), REQUEST_FOREGROUND_SERVICE_PERMISSION)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            android.util.Log.d("HEALTH_CHANNEL", "onRequestPermissionsResult: granted=$granted")
            flutterEngine?.let { engine ->
                MethodChannel(engine.dartExecutor.binaryMessenger, HEALTH_CHANNEL)
                    .invokeMethod("onPermissionResult", granted)
            }
        } else if (requestCode == REQUEST_FOREGROUND_SERVICE_PERMISSION) {
            val deniedPermissions = permissions.zip(grantResults.toTypedArray()).filter { it.second != PackageManager.PERMISSION_GRANTED }
            if (deniedPermissions.isNotEmpty()) {
                android.util.Log.e("MainActivity", "Permisos denegados: ${deniedPermissions.map { it.first }}")
            } else {
                android.util.Log.d("MainActivity", "Todos los permisos necesarios fueron otorgados.")
            }
        }
    }

    /**
     * Comprueba si la aplicación tiene permiso para acceder a los datos de uso.
     */
    fun hasUsageStatsPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Calcula la inactividad del dispositivo en un día específico.
     * Devuelve una lista de slots de inactividad.
     * Se define el día desde 00:00:00 hasta 23:59:59.
     * Se considera un slot cada gap entre eventos (ACTIVITY_RESUMED o ACTIVITY_PAUSED) mayor a un umbral mínimo.
     *
     * Los tiempos se devuelven en minutos relativos al inicio del día.
     * Ajusta [gapThreshold] según lo que consideres "inactividad relevante".
     */
    fun getInactivitySlots(context: Context, day: Long): List<Map<String, Any>> {
        val slots = mutableListOf<Map<String, Any>>()

        // Definir el inicio y fin del día
        val calendar = Calendar.getInstance(Locale.getDefault()).apply {
            timeInMillis = day
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis

        calendar.apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val endTime = calendar.timeInMillis

        // Umbral de inactividad (5 minutos en ms)
        val gapThresholdMs = 5 * 60 * 1000

        // Obtener el UsageStatsManager
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        // Preparamos el iterador de eventos
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        // Consideramos el gap inicial desde el inicio del día
        var previousTimestamp = startTime

        // Recorrer eventos relevantes
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                event.eventType == UsageEvents.Event.ACTIVITY_PAUSED) {

                val currentTimestamp = event.timeStamp
                val gap = currentTimestamp - previousTimestamp
                if (gap >= gapThresholdMs) {
                    // Convertimos los tiempos a minutos relativos al inicio del día.
                    val slotStart = previousTimestamp
                    val slotEnd = currentTimestamp
                    slots.add(mapOf("start" to slotStart, "end" to slotEnd))
                }
                previousTimestamp = currentTimestamp
            }
        }

        // Comprobar el gap final hasta el fin del día
        if (endTime - previousTimestamp >= gapThresholdMs) {
            val slotStart = previousTimestamp
            val slotEnd = endTime
            slots.add(mapOf("start" to slotStart, "end" to slotEnd))
        }

        // Calcular slots del día anterior
        val prevCalendar = Calendar.getInstance(Locale.getDefault()).apply {
            timeInMillis = day
            add(Calendar.DAY_OF_YEAR, -1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTimePrev = prevCalendar.timeInMillis
        prevCalendar.set(Calendar.HOUR_OF_DAY, 23)
        prevCalendar.set(Calendar.MINUTE, 59)
        prevCalendar.set(Calendar.SECOND, 59)
        prevCalendar.set(Calendar.MILLISECOND, 999)
        val endTimePrev = prevCalendar.timeInMillis

        // Consulta de eventos y cálculo de inactividad para el día anterior (igual que el día actual)
        val usageEventsPrev = usageStatsManager.queryEvents(startTimePrev, endTimePrev)
        var previousTimestampPrev = startTimePrev

        while (usageEventsPrev.hasNextEvent()) {
            usageEventsPrev.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                event.eventType == UsageEvents.Event.ACTIVITY_PAUSED) {

                val currentTimestamp = event.timeStamp
                val gap = currentTimestamp - previousTimestampPrev
                if (gap >= gapThresholdMs) {
                    val slotStart = previousTimestampPrev
                    val slotEnd = currentTimestamp
                    slots.add(mapOf("start" to slotStart, "end" to slotEnd))
                }
                previousTimestampPrev = currentTimestamp
            }
        }

        if (endTimePrev - previousTimestampPrev >= gapThresholdMs) {
            val slotStart = previousTimestampPrev
            val slotEnd = endTimePrev
            slots.add(mapOf("start" to slotStart, "end" to slotEnd))
        }

        return slots
    }
}
