import 'package:mrfit/data/database_helper.dart';

class CustomCache {
  final int id;
  final String key;
  final String value;

  CustomCache({
    required this.id,
    required this.key,
    required this.value,
  });

  factory CustomCache.fromJson(Map<String, dynamic> json) {
    return CustomCache(
      id: json['id'],
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
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

  static Future<void> set(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    final existingEntry = await getByKey(key);

    if (existingEntry != null) {
      await db.update(
        'custom_cache_cacheentry',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      await db.insert(
        'custom_cache_cacheentry',
        {'key': key, 'value': value},
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
