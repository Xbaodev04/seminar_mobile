import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _resendLoading = false;

  static const int _resendTtl = 60;
  int _secondsRemaining = _resendTtl;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = _resendTtl);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _reset() async {
    final otp = _otpCtrl.text.trim();
    final pwd = _passCtrl.text;
    if (otp.isEmpty) return AppToast.showError(context, 'Vui lòng nhập mã OTP');
    if (pwd.length < 6) return AppToast.showError(context, AppLocalizations.of(context)!.passwordMinLengthMsg);
    setState(() => _loading = true);
    try {
      await AuthService.instance.resetPassword(email: widget.email, otp: otp, newPassword: pwd);
      AppToast.showSuccess(context, AppLocalizations.of(context)!.resetSuccessMsg);
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      var s = e.toString();
      while (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
      AppToast.showError(context, s);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resendLoading = true);
    try {
      await AuthService.instance.forgotPassword(email: widget.email);
      AppToast.showSuccess(context, AppLocalizations.of(context)!.resetSentMsg);
      _startCountdown();
    } catch (e) {
      var s = e.toString();
      while (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
      AppToast.showError(context, s);
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final resendLabel = _secondsRemaining > 0 ? '${locale?.resendOtpText ?? 'Resend'} (${_formatTime(_secondsRemaining)})' : (locale?.resendOtpText ?? 'Resend');

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
                      Text(locale?.resetPasswordTitle ?? 'Reset password', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(locale?.resetPasswordDesc ?? 'Enter the code sent to your email and choose a new password', textAlign: TextAlign.center),
                      const SizedBox(height: 12),

                      Align(alignment: Alignment.centerLeft, child: Text('${locale?.codeSentTo ?? 'Code sent to:'} ${widget.email}', style: const TextStyle(color: Colors.black54))),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _otpCtrl,
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.confirmation_number_outlined), labelText: locale?.otpLabel ?? 'OTP'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), labelText: locale?.newPasswordLabel ?? 'New password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _reset,
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Theme.of(context).colorScheme.primary),
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(locale?.resetButton ?? 'Reset', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: (_resendLoading || _secondsRemaining > 0) ? null : _resend,
                            child: _resendLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()) : Text(resendLabel),
                          ),
                          TextButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/login'), child: Text(locale?.backToLogin ?? 'Back to login')),
                        ],
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
