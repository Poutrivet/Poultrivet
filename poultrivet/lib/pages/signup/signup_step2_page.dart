import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// FirebaseAuth imported above for recovery flow in _complete()
import '../../core/theme.dart';
import '../../models/farmer_model.dart';
import '../../services/auth_service.dart';
import '../home_page.dart';

class SignupStep2Page extends StatefulWidget {
  final String fullName;
  final String district;
  final String phoneNumber;
  final String password;

  const SignupStep2Page({
    super.key,
    required this.fullName,
    required this.district,
    required this.phoneNumber,
    required this.password,
  });

  @override
  State<SignupStep2Page> createState() => _SignupStep2PageState();
}

class _SignupStep2PageState extends State<SignupStep2Page> {
  bool _termsAccepted = false;
  bool _dataConsentAccepted = false;
  bool _isLoading = false;

  Future<void> _complete() async {
    if (!_termsAccepted) {
      _showSnack('Please accept the Terms & Conditions to continue');
      return;
    }
    if (!_dataConsentAccepted) {
      _showSnack('Please accept the Data & Image Collection disclosure');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Create Firebase account (normal signup flow) ───────────────────────
      // If password is empty it means the account already exists (recovery
      // flow from AuthGate) — just use the currently signed-in user instead.
      String uid;
      if (widget.password.isNotEmpty) {
        final cred = await AuthService().signUp(
          phoneNumber: widget.phoneNumber,
          password: widget.password,
        );
        uid = cred.user!.uid;
      } else {
        uid = FirebaseAuth.instance.currentUser!.uid;
      }

      // ── Save farmer profile to Firestore ─────────────────────────────────────
      final farmer = FarmerModel(
        uid: uid,
        fullName: widget.fullName,
        district: widget.district,
        phoneNumber: widget.phoneNumber,
        termsAccepted: _termsAccepted,
        dataConsentAccepted: _dataConsentAccepted,
        createdAt: DateTime.now(),
      );

      await AuthService().saveFarmerProfile(farmer);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
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
      case 'email-already-in-use':
        return 'An account with this phone number already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: PoulvetTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: const Text('Almost done!',
            style: TextStyle(
                color: PoulvetTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(step: 2),
            const SizedBox(height: 28),
            const Text("Review & Accept",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: PoulvetTheme.textDark)),
            const SizedBox(height: 6),
            const Text(
                "Please read and accept the following before we create your account",
                style: TextStyle(fontSize: 14, color: PoulvetTheme.textGrey)),
            const SizedBox(height: 24),

            // Terms card
            _ConsentCard(
              icon: Icons.gavel_rounded,
              title: 'Terms & Conditions',
              description:
                  'These terms govern your use of PoulVet, including your rights and '
                  'responsibilities as a farmer using our AI diagnostic tools.',
              onReadMore: () => _openSheet(context, const _TermsSheet()),
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v!),
              checkLabel: 'I have read and accept the Terms & Conditions',
            ),
            const SizedBox(height: 16),

            // Data consent card
            _ConsentCard(
              icon: Icons.photo_library_outlined,
              title: 'Data & Image Collection Disclosure',
              description:
                  'PoulVet collects fecal images and diagnostic data to improve our AI. '
                  'Your data is anonymised and secured.',
              onReadMore: () => _openSheet(context, const _DataConsentSheet()),
              value: _dataConsentAccepted,
              onChanged: (v) => setState(() => _dataConsentAccepted = v!),
              checkLabel: 'I consent to anonymised data collection for AI improvement',
            ),

            const Spacer(),

            ElevatedButton(
              style: PoulvetTheme.primaryButton,
              onPressed: _isLoading ? null : _complete,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Create Account & Continue 🎉'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}

// ─── Consent card ─────────────────────────────────────────────────────────────
class _ConsentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onReadMore;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String checkLabel;

  const _ConsentCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onReadMore,
    required this.value,
    required this.onChanged,
    required this.checkLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? PoulvetTheme.primary : PoulvetTheme.border,
          width: value ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PoulvetTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: PoulvetTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: PoulvetTheme.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  fontSize: 13, color: PoulvetTheme.textGrey, height: 1.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onReadMore,
            child: const Text('Read full document →',
                style: TextStyle(
                    color: PoulvetTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: PoulvetTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(checkLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        color: PoulvetTheme.textDark,
                        height: 1.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Scrollable sheet wrapper ─────────────────────────────────────────────────
class _ScrollableSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _ScrollableSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: PoulvetTheme.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: PoulvetTheme.textDark)),
              const SizedBox(height: 16),
              Expanded(
                  child: SingleChildScrollView(
                      controller: controller, child: child)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: PoulvetTheme.primaryButton,
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();
  @override
  Widget build(BuildContext context) =>
      const _ScrollableSheet(title: 'Terms & Conditions', child: _TermsContent());
}

class _DataConsentSheet extends StatelessWidget {
  const _DataConsentSheet();
  @override
  Widget build(BuildContext context) =>
      const _ScrollableSheet(title: 'Data & Image Collection Disclosure', child: _DataConsentContent());
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();
  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Section('1. Acceptance of Terms',
          'By creating a PoulVet account, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the app.'),
      _Section('2. Use of the Service',
          'PoulVet is a diagnostic aid and does not replace professional veterinary advice. All diagnoses should be confirmed by a licensed veterinarian.'),
      _Section('3. Account Responsibility',
          'You are responsible for maintaining the confidentiality of your account credentials. You must provide accurate information including your name, district, and phone number.'),
      _Section('4. Intellectual Property',
          'All content, AI models, and software within PoulVet are the intellectual property of the PoulVet team. You may not copy, distribute, or reverse engineer any part of the application.'),
      _Section('5. Limitation of Liability',
          'PoulVet is not liable for any losses or damages arising from reliance on AI diagnostic results. The service is provided "as is" without warranty of any kind.'),
      _Section('6. Governing Law',
          'These Terms are governed by the laws of the Republic of Uganda. Any disputes shall be resolved in the courts of Uganda.'),
      SizedBox(height: 24),
    ]);
  }
}

class _DataConsentContent extends StatelessWidget {
  const _DataConsentContent();
  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Section('What we collect',
          'When you use PoulVet to diagnose your poultry, the following is collected:\n\n• Fecal images you submit\n• Diagnostic results and confidence scores\n• Device metadata\n• Your district (region level)\n• Timestamps of diagnoses'),
      _Section('Why we collect it',
          'This data is used exclusively to improve the accuracy of our AI disease detection models.'),
      _Section('How we protect your data',
          'All images and data are:\n\n• Encrypted in transit and at rest\n• Stored on secure Firebase Cloud Storage\n• Anonymised before use in model training\n• Never sold to third parties'),
      _Section('Your rights',
          'You may request deletion of your data at any time by contacting our support. You may also withdraw this consent in Settings → Privacy.'),
      _Section('Data retention',
          'Images and diagnostic data are retained for a maximum of 3 years for model training purposes, after which they are permanently deleted.'),
      SizedBox(height: 24),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: PoulvetTheme.textDark)),
        const SizedBox(height: 6),
        Text(body,
            style: const TextStyle(
                fontSize: 14, color: PoulvetTheme.textGrey, height: 1.6)),
      ]),
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
