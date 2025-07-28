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
    db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        descripcion TEXT,
        icon TEXT
      );
    ''');
  }

  Future<void> insertLocation(double lat, double lng, String descripcion, String icon) async {
    db.execute(
      'INSERT INTO locations (latitud, longitud, descripcion, icon) VALUES (?, ?, ?, ?);',
      [lat, lng, descripcion, icon],
    );
  }

  List<Map<String, dynamic>> getAllLocations() {
    final result = db.select('SELECT * FROM locations');
    return result.map((row) => {
      'id': row['id'],
      'latitud': row['latitud'],
      'longitud': row['longitud'],
      'descripcion': row['descripcion'],
      'icon': row['icon'],
    }).toList();
  }

  void updateLocation(int id, double lat, double lng, String descripcion, String icon) {
    db.execute(
      'UPDATE locations SET latitud = ?, longitud = ?, descripcion = ?, icon = ? WHERE id = ?;',
      [lat, lng, descripcion, icon, id],
    );
  }

  void deleteLocation(int id) {
    db.execute('DELETE FROM locations WHERE id = ?;', [id]);
  }

  void close() {
    db.dispose();
  }
}
