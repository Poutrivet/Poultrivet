import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/district_picker_field.dart';
import 'signup_step2_page.dart';

class SignupStep1Page extends StatefulWidget {
  const SignupStep1Page({super.key});

  @override
  State<SignupStep1Page> createState() => _SignupStep1PageState();
}

class _SignupStep1PageState extends State<SignupStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _countryCode = '+256';
  String? _selectedDistrict;
  String? _districtError;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _next() {
    if (_selectedDistrict == null) {
      setState(() => _districtError = 'Please select your district');
    } else {
      setState(() => _districtError = null);
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null) return;

    // No Firebase call yet — account only created after terms are accepted
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupStep2Page(
          fullName: _nameController.text.trim(),
          district: _selectedDistrict!,
          phoneNumber: '$_countryCode${_phoneController.text.trim()}',
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PoulvetTheme.lightBg,
      appBar: AppBar(
        backgroundColor: PoulvetTheme.lightBg,
        elevation: 0,
        leading: BackButton(color: PoulvetTheme.textDark),
        title: const Text('Create Account',
            style: TextStyle(
                color: PoulvetTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepIndicator(step: 1),
              const SizedBox(height: 28),
              const Text("Your details",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: PoulvetTheme.textDark)),
              const SizedBox(height: 6),
              const Text("Fill in your information to get started",
                  style: TextStyle(fontSize: 14, color: PoulvetTheme.textGrey)),
              const SizedBox(height: 28),

              // Full name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: PoulvetTheme.inputDecoration(
                    'Full Name', hint: 'e.g. John Musoke', icon: Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),

              // District
              DistrictPickerField(
                value: _selectedDistrict,
                errorText: _districtError,
                onChanged: (d) => setState(() {
                  _selectedDistrict = d;
                  _districtError = null;
                }),
              ),
              const SizedBox(height: 16),

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
                onChanged: (val) => setState(() => _countryCode = val!),
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: PoulvetTheme.inputDecoration(
                    'Phone Number', hint: 'e.g. 700 123456', icon: Icons.phone_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  if (v.trim().length < 7) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: PoulvetTheme.inputDecoration('Password', icon: Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: PoulvetTheme.textGrey, size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: PoulvetTheme.inputDecoration('Confirm Password', icon: Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: PoulvetTheme.textGrey, size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: PoulvetTheme.primaryButton,
                onPressed: _next,
                child: const Text('Continue  →'),
              ),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: PoulvetTheme.textGrey, fontSize: 14),
                      children: [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(color: PoulvetTheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final active = i + 1 <= step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? PoulvetTheme.primary : PoulvetTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
