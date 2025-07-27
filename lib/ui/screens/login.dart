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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Bienvenido a MapaClip"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onLoginPressed,
            child: const Text("Iniciar sesión"),
          ),
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
