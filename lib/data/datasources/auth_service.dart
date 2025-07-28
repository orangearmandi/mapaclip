import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_storage.dart';

class AuthService with ChangeNotifier {
  late Auth0 auth0;
  Credentials? _credentials;
  bool isBusy = false;
  String errorMessage = '';

  AuthService() {
    final domain = dotenv.env['AUTH0_DOMAIN']!;
    final clientId = dotenv.env['AUTH0_CLIENT_ID']!;
    auth0 = Auth0(domain, clientId);
    _loadStoredCredentials();
  }

  Credentials? get credentials => _credentials;
  UserProfile? get user => _credentials?.user;
  bool get isLoggedIn => _credentials != null;

  Future<void> _loadStoredCredentials() async {
    final stored = AuthStorage.instance.retrieve();
    if (stored != null) {
      try {
        _credentials = stored as Credentials?;
        notifyListeners();
      } catch (e) {
        _credentials = null;
      }
    }
  }

  Future<void> loginAction() async {
    isBusy = true;
    errorMessage = '';
    notifyListeners();

    try {
      final creds = await auth0.webAuthentication(scheme: 'mapaclip').login();
      _credentials = creds;
      AuthStorage.instance.save(jsonEncode(creds));
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logoutAction() async {
    await auth0.webAuthentication(scheme: 'mapaclip').logout();
    _credentials = null;
    AuthStorage.instance.clear();
    notifyListeners();
  }
}
