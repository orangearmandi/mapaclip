import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:mapaclip/data/datasources/auth_service.dart';
import 'package:mapaclip/ui/screens/interactive_map.dart';
import 'package:mapaclip/ui/screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: authService.isBusy
              ? const CircularProgressIndicator()
              : authService.isLoggedIn
              ? const InteractiveMap()
              : Login(
            onLoginPressed: authService.loginAction,
            errorMessage: authService.errorMessage,
          ),
        ),
      ),
    );
  }
}

