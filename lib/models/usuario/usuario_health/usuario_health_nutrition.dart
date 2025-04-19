part of '../usuario.dart';

extension UsuarioHealthNutritionExtension on Usuario {
  // Método para obtener la diferencia calórica por fecha
  Future<double?> getByDate(DateTime date) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'nutricion_diferenciacalorica',
        where: 'fecha = ? AND usuario_id = ?',
        whereArgs: [DateFormat('yyyy-MM-dd').format(date), id],
      );

      if (results.isNotEmpty) {
        return results.first['kcal'] as double?;
      }
      return null;
    } catch (e) {
      Logger().e('Error al obtener diferencia calórica: $e');
      return null;
    }
  }

  // Método para establecer la diferencia calórica
  Future<bool> setDiferenciaCalorica(DateTime date, double kcal) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = {
        'fecha': DateFormat('yyyy-MM-dd').format(date),
        'kcal': kcal,
        'usuario_id': id,
      };

      // Intentar actualizar primero
      final count = await db.update(
        'nutricion_diferenciacalorica',
        data,
        where: 'fecha = ? AND usuario_id = ?',
        whereArgs: [data['fecha'], id],
      );

      // Si no existe, insertar
      if (count == 0) {
        await db.insert('nutricion_diferenciacalorica', data);
      }

      return true;
    } catch (e) {
      Logger().e('Error al establecer diferencia calórica: $e');
      return false;
    }
  }
}
