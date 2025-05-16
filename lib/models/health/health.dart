import 'package:mrfit/models/usuario/usuario.dart';
import 'package:health/health.dart';

/// Clase para obtener un resumen de salud del usuario en un rango de fechas o por UUID.
/// Utiliza una sola llamada para obtener varios tipos de datos de salud.
class HealthSummary {
  final Usuario usuario;

  HealthSummary(this.usuario);

  /// Obtiene el resumen de salud entre [start] y [end] usando una sola llamada a Health.
  /// Devuelve un mapa con frecuencia cardiaca, pasos y distancia.
  Future<Map<String, dynamic>> getSummaryByDateRange(DateTime start, DateTime end) async {
    // Definir los tipos de datos a consultar
    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_DELTA,
    ];

    // Obtener todos los datos de los tipos especificados en el rango
    final dataPoints = await Health().getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );

    // Filtrar y agrupar los datos por tipo
    final heartRates = dataPoints.where((dp) => dp.type == HealthDataType.HEART_RATE).map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : 0.0).toList();

    final steps = dataPoints.where((dp) => dp.type == HealthDataType.STEPS).fold<int>(0, (sum, dp) => sum + (dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0));

    final distance = dataPoints.where((dp) => dp.type == HealthDataType.DISTANCE_DELTA).fold<int>(0, (sum, dp) => sum + (dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0));

    return {
      'HEART_RATE': heartRates,
      'STEPS': steps,
      'DISTANCE_DELTA': distance,
    };
  }
}
