import 'package:flutter/material.dart';
import 'package:mapaclip/ui/screens/interactive_map.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    //final auth = Provider.of<AuthProvider>(context);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/clima.png', width: 100),
              TextFormField(
                decoration: inputDecoration.copyWith(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) => value!.isEmpty ? 'Ingrese su correo' : null,
                onSaved: (value) => email = value!,
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: inputDecoration.copyWith(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator:
                    (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                onSaved: (value) => password = value!,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                child: const Text('Ingresar'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => InteractiveMap()),
                  );
                },
              ),
              Text(error, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: () {},
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
