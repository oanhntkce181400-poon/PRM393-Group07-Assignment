import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();

  Future login() async {
    if (!formKey.currentState!.validate()) return;

    final error = await context.read<AuthProvider>().login(
      email.text,
      pass.text,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Nhập email";
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                      return "Email sai";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (v) => v!.length < 6 ? "≥ 6 ký tự" : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: login, child: const Text("Login")),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text("Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
