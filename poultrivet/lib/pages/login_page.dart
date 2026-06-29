import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'signup/signup_step1_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _countryCode = '+256';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+256', 'name': '🇺🇬 Uganda'},
    {'code': '+254', 'name': '🇰🇪 Kenya'},
    {'code': '+255', 'name': '🇹🇿 Tanzania'},
    {'code': '+250', 'name': '🇷🇼 Rwanda'},
    {'code': '+1',   'name': '🇺🇸 USA'},
    {'code': '+44',  'name': '🇬🇧 UK'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final fullPhone = '$_countryCode${_phoneController.text.trim()}';
      await AuthService().signIn(
        phoneNumber: fullPhone,
        password: _passwordController.text,
      );
      // AuthGate will handle navigation automatically
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnack(_friendlyError(e.code));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Something went wrong. Please try again.');
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this phone number.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Phone number or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return 'Login failed. Check your details and try again.';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: PoulvetTheme.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PoulvetTheme.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/icon/icon.png",
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Welcome back 👋",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PoulvetTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Sign in to your PoulVet account",
                  style:
                      TextStyle(fontSize: 15, color: PoulvetTheme.textGrey),
                ),

                const SizedBox(height: 36),

                // Country code
                DropdownButtonFormField<String>(
                  value: _countryCode,
                  decoration: PoulvetTheme.inputDecoration('Country Code'),
                  items: _countryCodes
                      .map((c) => DropdownMenuItem(
                            value: c['code'],
                            child: Text('${c['name']}  (${c['code']})'),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _countryCode = val!),
                ),

                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: PoulvetTheme.inputDecoration(
                    'Phone Number',
                    hint: 'e.g. 700 123456',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: PoulvetTheme.inputDecoration(
                    'Password',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: PoulvetTheme.textGrey,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                ElevatedButton(
                  style: PoulvetTheme.primaryButton,
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Sign In'),
                ),

                const SizedBox(height: 32),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupStep1Page()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            color: PoulvetTheme.textGrey, fontSize: 14),
                        children: [
                          TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              color: PoulvetTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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