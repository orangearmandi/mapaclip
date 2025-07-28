import 'package:flutter/foundation.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthService with ChangeNotifier {
  late final Auth0 auth0;
  final _storage = const FlutterSecureStorage();
  Credentials? _credentials;
  bool isBusy = false;
  String errorMessage = '';

  static const _credentialsKey = 'auth0_credentials';

  AuthService() {
    final domain = dotenv.env['AUTH0_DOMAIN']!;
    final clientId = dotenv.env['AUTH0_CLIENT_ID']!;
    auth0 = Auth0(domain, clientId);
    _loadCredentials(); // cargar al inicio
  }

  Credentials? get credentials => _credentials;
  UserProfile? get user => _credentials?.user;
  bool get isLoggedIn => _credentials != null;

  Future<void> _loadCredentials() async {
    final stored = await _storage.read(key: _credentialsKey);
    if (stored != null) {
      try {
        final json = jsonDecode(stored);
        _credentials = Credentials.fromMap(json);
        notifyListeners();
      } catch (_) {
        await _storage.delete(key: _credentialsKey);
      }
    }
  }
  Future<void> init() async {
    await _loadCredentials();
  }
  Future<void> _saveCredentials(Credentials credentials) async {
    final jsonStr = jsonEncode(credentials);
    await _storage.write(key: _credentialsKey, value: jsonStr);
  }

  Future<void> loginAction() async {
    isBusy = true;
    errorMessage = '';
    notifyListeners();

    try {
      final Credentials creds = await auth0.webAuthentication(scheme: 'mapaclip').login();
      _credentials = creds;
      await _saveCredentials(creds);
    } on Exception catch (e) {
      errorMessage = e.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logoutAction() async {
    try {
      await auth0.webAuthentication(scheme: 'mapaclip').logout();
    } catch (_) {}
    _credentials = null;
    await _storage.delete(key: _credentialsKey);
    notifyListeners();
  }
}
