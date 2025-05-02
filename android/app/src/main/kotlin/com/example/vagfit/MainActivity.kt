package com.example.vagfit

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Process
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {

    private val SCREEN_CHANNEL = "com.vagfit/screen_state"
    private val USAGE_CHANNEL = "com.vagfit/usage_stats"
    private val HEALTH_CHANNEL = "com.vagfit/health"
    private val REQUEST_CODE = 1001
    private var screenStateReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal para el API de UsageStats
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    val permissionGranted = hasUsageStatsPermission(this)
                    result.success(permissionGranted)
                }
                "openUsageStatsSettings" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
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
