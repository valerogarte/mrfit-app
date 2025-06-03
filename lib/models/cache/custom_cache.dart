import 'package:mrfit/data/database_helper.dart';

class CustomCache {
  final int id;
  final String key;
  final String value;
  final DateTime created; // Fecha de creación del registro
  final DateTime? validUntil; // Fecha de expiración opcional

  CustomCache({
    required this.id,
    required this.key,
    required this.value,
    required this.created,
    this.validUntil,
  });

  factory CustomCache.fromJson(Map<String, dynamic> json) {
    return CustomCache(
      id: json['id'],
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      created: DateTime.parse(json['created']),
      validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'created': created.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
    };
  }

  static Future<CustomCache?> getByKey(String key) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'custom_cache_cacheentry',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;
    return CustomCache.fromJson(result.first);
  }

  /// Guarda o actualiza un registro de caché.
  /// Si existe, actualiza value, valid_until y mantiene created.
  /// Si no existe, crea uno nuevo con la fecha actual.
  static Future<void> set(String key, String value, {DateTime? validUntil}) async {
    final db = await DatabaseHelper.instance.database;
    final existingEntry = await getByKey(key);

    if (existingEntry != null) {
      await db.update(
        'custom_cache_cacheentry',
        {
          'value': value,
          'valid_until': validUntil?.toIso8601String(),
        },
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      await db.insert(
        'custom_cache_cacheentry',
        {
          'key': key,
          'value': value,
          'created': DateTime.now().toIso8601String(),
          'valid_until': validUntil?.toIso8601String(),
        },
      );
    }
  }

  static Future<void> deleteByKey(String key) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'custom_cache_cacheentry',
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}
