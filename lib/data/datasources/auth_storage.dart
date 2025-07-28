import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class AuthStorage {
  static final AuthStorage instance = AuthStorage._internal();
  late Database _db;

  AuthStorage._internal();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'auth.db');
    _db = sqlite3.open(dbPath);

    _db.execute('''
      CREATE TABLE IF NOT EXISTS session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        access_token TEXT
      );
    ''');
  }

  Future<void> saveSession(String accessToken) async {
    _db.execute('DELETE FROM session;');
    _db.execute(
      'INSERT INTO session (access_token) VALUES (?);',
      [accessToken],
    );
  }

  String? getAccessToken() {
    try {
      final result = _db.select('SELECT access_token FROM session LIMIT 1;');
      if (result.isNotEmpty) {
        return result.first['access_token'] as String;
      }
    } catch (e) {
      print('Error al leer access_token: $e');
    }
    return null;
  }


  Future<void> clearSession() async {
    _db.execute('DELETE FROM session;');
  }

  void close() {
    _db.dispose();
  }
}
