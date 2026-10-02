import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;
  final String? fullName;
  final String? password;
  final String? username;

  const VerifyOtpPage({Key? key, required this.email, this.fullName, this.password, this.username}) : super(key: key);

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resendLoading = false;

  static const int _resendTtl = 60; // seconds
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

  String _errMsg(Object e) {
    var s = e.toString();
    while (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
    return s;
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.trim().isEmpty) return AppToast.showError(context, 'Vui lòng nhập mã OTP');
    setState(() => _loading = true);
    try {
      await AuthService.instance.verifyAndComplete(email: widget.email, otp: _otpCtrl.text.trim());
      AppToast.showSuccess(context, 'Xác thực thành công');
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      AppToast.showError(context, _errMsg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (widget.fullName == null || widget.password == null) {
      return AppToast.showError(context, 'Vui lòng trở lại trang đăng ký để gửi lại mã');
    }
    setState(() => _resendLoading = true);
    try {
      await AuthService.instance.register(username: widget.username, email: widget.email, password: widget.password!, full_name: widget.fullName!);
      AppToast.showSuccess(context, 'Mã OTP đã được gửi lại');
      // restart countdown
      _startCountdown();
    } catch (e) {
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final resendLabel = _secondsRemaining > 0
        ? '${locale?.resendOtpText ?? 'Gửi lại mã'} (${_formatTime(_secondsRemaining)})'
        : (locale?.resendOtpText ?? 'Gửi lại mã');

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
                      Text(locale?.emailVerificationTitle ?? 'Xác thực email', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text(locale?.emailVerificationDesc ?? 'Nhập mã OTP đã gửi tới email của bạn', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text('Mã đã gửi tới: ${widget.email}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _otpCtrl,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.confirmation_number_outlined), labelText: 'Mã OTP'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verify,
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Theme.of(context).colorScheme.primary),
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(locale?.verifyButtonText ?? 'Xác thực', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                            child: Text(locale?.backToRegister ?? 'Trở lại đăng ký'),
                          ),
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
