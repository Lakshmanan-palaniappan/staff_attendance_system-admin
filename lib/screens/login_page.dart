import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_api.dart';
import '../widgets/gradient_header.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  // Controllers
  final loginUserController = TextEditingController();
  final loginPassController = TextEditingController();
  final regUserController = TextEditingController();
  final regPassController = TextEditingController();
  final regConfirmPassController = TextEditingController();

  bool isRegisterMode = false;
  bool loading = false;
  bool showPass = false;
  bool showRegPass = false;
  bool showRegConfirm = false;

  @override
  void dispose() {
    loginUserController.dispose();
    loginPassController.dispose();
    regUserController.dispose();
    regPassController.dispose();
    regConfirmPassController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // LOGIN
  Future<void> _login() async {
    final username = loginUserController.text.trim();
    final password = loginPassController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _snack("Enter username and password", error: true);
      return;
    }

    setState(() => loading = true);

    try {
      await AdminApi.loginAdmin(username, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isAdminLogged", true);
      await prefs.setString("adminUsername", username);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      _snack("Login failed: ${e.toString()}", error: true);
    } finally {
      setState(() => loading = false);
    }
  }

  // REGISTER
  Future<void> _register() async {
    final username = regUserController.text.trim();
    final password = regPassController.text.trim();
    final confirm = regConfirmPassController.text.trim();

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      _snack("Fill all fields", error: true);
      return;
    }

    if (password != confirm) {
      _snack("Passwords do not match", error: true);
      return;
    }

    setState(() => loading = true);

    try {
      await AdminApi.registerAdmin(username, password);

      _snack("Registered successfully!");
      setState(() => isRegisterMode = false);

      regUserController.clear();
      regPassController.clear();
      regConfirmPassController.clear();
    } catch (e) {
      _snack("Registration failed: ${e.toString()}", error: true);
    } finally {
      setState(() => loading = false);
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xfff2f3f7),
      body: Column(
        children: [
          const GradientHeader(title: "Attendance Control Panel"),

          Expanded(
            child: Center(
              child: Card(
                elevation: 10,
                shadowColor: Colors.indigo.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                margin: const EdgeInsets.all(24),

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(28),
                  width: isWide ? 450 : double.infinity,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRegisterMode ? "Create Admin Account" : "Admin Login",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 25),

                      if (!isRegisterMode) _loginForm(),
                      if (isRegisterMode) _registerForm(),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          setState(() => isRegisterMode = !isRegisterMode);
                        },
                        child: Text(
                          isRegisterMode
                              ? "Already have an account? Login"
                              : "Create new admin account",
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LOGIN FORM ----------------
  Widget _loginForm() {
    return Column(
      children: [
        _inputBox(
          controller: loginUserController,
          label: "Username",
          icon: Icons.person,
        ),
        const SizedBox(height: 16),

        _inputBox(
          controller: loginPassController,
          label: "Password",
          icon: Icons.lock,
          obscureText: !showPass,
          toggle: () => setState(() => showPass = !showPass),
          showToggle: true,
        ),
        const SizedBox(height: 28),

        _gradientButton(
          text: "Login",
          onTap: loading ? null : _login,
          loading: loading,
        ),
      ],
    );
  }

  // ---------------- REGISTER FORM ----------------
  Widget _registerForm() {
    return Column(
      children: [
        _inputBox(
          controller: regUserController,
          label: "Username",
          icon: Icons.person_add_alt_1,
        ),
        const SizedBox(height: 16),

        _inputBox(
          controller: regPassController,
          label: "Password",
          icon: Icons.lock,
          obscureText: !showRegPass,
          toggle: () => setState(() => showRegPass = !showRegPass),
          showToggle: true,
        ),
        const SizedBox(height: 16),

        _inputBox(
          controller: regConfirmPassController,
          label: "Confirm Password",
          icon: Icons.lock_outline,
          obscureText: !showRegConfirm,
          toggle: () => setState(() => showRegConfirm = !showRegConfirm),
          showToggle: true,
        ),
        const SizedBox(height: 28),

        _gradientButton(
          text: "Register",
          onTap: loading ? null : _register,
          loading: loading,
        ),
      ],
    );
  }

  // ---------------- CUSTOM INPUT BOX ----------------
  Widget _inputBox({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool showToggle = false,
    VoidCallback? toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigo),
        labelText: label,
        filled: true,
        fillColor: const Color(0xffeef1f7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: showToggle
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: toggle,
              )
            : null,
      ),
    );
  }

  // ---------------- GRADIENT BUTTON ----------------
  Widget _gradientButton({
    required String text,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
