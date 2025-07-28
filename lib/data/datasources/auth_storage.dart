import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class AuthStorage {
  late final Database db;

  AuthStorage._internal() {
    final dbPath = p.join(Directory.current.path, 'auth_data.db');
    db = sqlite3.open(dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS credentials (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL
      );
    ''');
  }

  static final AuthStorage instance = AuthStorage._internal();

  void save(String jsonData) {
    db.execute('DELETE FROM credentials;');
    db.execute('INSERT INTO credentials (data) VALUES (?);', [jsonData]);
  }

  String? retrieve() {
    final result = db.select('SELECT data FROM credentials LIMIT 1;');
    return result.isNotEmpty ? result.first['data'] as String : null;
  }

  void clear() {
    db.execute('DELETE FROM credentials;');
  }
}
