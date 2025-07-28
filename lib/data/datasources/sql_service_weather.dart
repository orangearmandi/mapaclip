import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SqlService {
  static final SqlService instance = SqlService._init();
  late final Database db;

  SqlService._init() {
    _initDb();
  }

  Future<void> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'locations.sqlite');
    final file = File(dbPath);

    db = sqlite3.open(file.path);

    // Crear tabla si no existe
    db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ciudad TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        descripcion TEXT,
        icon TEXT,
        temperatura REAL,
        fecha TEXT
      );
    ''');

    // Agregar columnas si no existen (si ya están, se ignora el error)
    try {
      db.execute("ALTER TABLE locations ADD COLUMN temperatura REAL;");
    } catch (_) {}
    try {
      db.execute("ALTER TABLE locations ADD COLUMN fecha TEXT;");
    } catch (_) {}
  }

  Future<void> insertLocation({
    required String ciudad,
    required double lat,
    required double lng,
    required String descripcion,
    required String icon,
    required double temperatura,
    String? fecha, // opcional
  }) async {
    final now = fecha ?? DateTime.now().toIso8601String();
    db.execute(
      'INSERT INTO locations (ciudad, latitud, longitud, descripcion, icon, temperatura, fecha) VALUES (?, ?, ?, ?, ?, ?, ?);',
      [ciudad, lat, lng, descripcion, icon, temperatura, now],
    );
  }

  List<Map<String, dynamic>> getAllLocations() {
    final result = db.select('SELECT * FROM locations');
    return result.map((row) => {
      'id': row['id'],
      'ciudad': row['ciudad'],
      'latitud': row['latitud'],
      'longitud': row['longitud'],
      'descripcion': row['descripcion'],
      'icon': row['icon'],
      'temperatura': row['temperatura'],
      'fecha': row['fecha'],
    }).toList();
  }

  void updateLocation({
    required int id,
    required double temperatura,
    required String ciudad,
    required double lat,
    required double lng,
    required String descripcion,
    required String fecha,
    required String icon,
  }) {
    db.execute(
      'UPDATE locations SET ciudad = ?, latitud = ?, longitud = ?, descripcion = ?, icon = ?, temperatura = ?, fecha = ? WHERE id = ?;',
      [ciudad, lat, lng, descripcion, icon, temperatura, fecha, id],
    );
  }

  void deleteLocation(int id) {
    db.execute('DELETE FROM locations WHERE id = ?;', [id]);
  }

  void close() {
    db.dispose();
  }
}
