import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  Future register() async {
    if (!formKey.currentState!.validate()) return;

    final error = await context.read<AuthProvider>().register(
      name.text,
      email.text,
      pass.text,
    );

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: name,
              validator: (v) => v!.isEmpty ? "Nhập tên" : null,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextFormField(
              controller: email,
              validator: (v) =>
                  !RegExp(r'\S+@\S+\.\S+').hasMatch(v!) ? "Email sai" : null,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextFormField(
              controller: pass,
              obscureText: true,
              validator: (v) => v!.length < 6 ? "≥ 6 ký tự" : null,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            TextFormField(
              controller: confirm,
              obscureText: true,
              validator: (v) => v != pass.text ? "Không khớp" : null,
              decoration: const InputDecoration(labelText: "Confirm"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}
