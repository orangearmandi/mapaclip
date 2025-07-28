import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final String errorMessage;

  const Login({
    super.key,
    required this.onLoginPressed,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              Image.asset(
                'assets/clima.png',
                height: 120,
              ),
              const SizedBox(height: 30),

              // TÍTULO
              Text(
                "Bienvenido a MapaClip",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // BOTÓN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onLoginPressed,
                  icon: const Icon(Icons.login),
                  label: const Text("Iniciar sesión con Auth0"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // ERROR
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
