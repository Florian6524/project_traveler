import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final role = doc.data()?['role'];

      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } catch (e) {
      _showError("Unexpected error");
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _signup() async {
    if (passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    if (nameController.text.isEmpty) {
      _showError("Please enter a name");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'points': 0,
        'role': 'user',
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Signup failed");
    } catch (e) {
      _showError("Unexpected error");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isLogin ? "Welcome back" : "Create account",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLogin
                      ? "Log in to continue exploring"
                      : "Sign up to start earning points",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (!isLogin) ...[
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: "Name",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ElevatedButton(
                                  onPressed: isLogin ? _login : _signup,
                                  child: Text(
                                    isLogin ? "Login" : "Sign Up",
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
