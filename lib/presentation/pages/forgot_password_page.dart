import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return AppToast.showError(context, AppLocalizations.of(context)!.enterEmailMsg);
    setState(() => _loading = true);
    try {
      await AuthService.instance.forgotPassword(email: email);
      AppToast.showSuccess(context, AppLocalizations.of(context)!.resetSentMsg);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResetPasswordPage(email: email)));
    } catch (e) {
      var s = e.toString();
      while (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
      AppToast.showError(context, s);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: kGrapGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 64, height: 64, child: Image.asset('lib/assets/imgs/favicon.png')),
                      const SizedBox(height: 12),
                      Text(locale?.forgotPassword ?? 'Forgot password', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text(locale?.forgotPasswordDesc ?? 'Enter your email to receive a reset code.', textAlign: TextAlign.center),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.email_outlined), labelText: locale?.emailLabel ?? 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _send,
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Theme.of(context).colorScheme.primary),
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(locale?.sendResetButton ?? 'Send', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                        child: Text(locale?.backToLogin ?? 'Back to login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
