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

    if (error != null && mounted) {
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
      backgroundColor: Colors.white, // nền ngoài trắng
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange[200], // màu cam nhạt
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.deepOrange),
                    ),
                    validator: (v) => v!.isEmpty ? "Nhập tên" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.deepOrange),
                    ),
                    validator: (v) => !RegExp(r'\S+@\S+\.\S+').hasMatch(v!)
                        ? "Email sai"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pass,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.deepOrange),
                    ),
                    validator: (v) => v!.length < 6 ? "≥ 6 ký tự" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.deepOrange,
                      ),
                    ),
                    validator: (v) => v != pass.text ? "Không khớp" : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // nút cam nhạt
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            Colors.orange[100], // nút quay lại cam nhạt hơn
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.orange.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Back",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
