import 'package:flutter/material.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty) {
      return AppToast.showError(context, locale?.enterPasswordMsg ?? 'Enter password');
    }
    if (newPass.length < 6) {
      return AppToast.showError(context, locale?.passwordMinLengthMsg ?? 'Password must be at least 6 characters');
    }
    if (newPass != confirm) {
      return AppToast.showError(context, locale?.passwordMismatchMsg ?? 'Passwords do not match');
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.changePassword(currentPassword: current, newPassword: newPass);
      AppToast.showSuccess(context, locale?.resetSuccessMsg ?? 'Password changed successfully');
      Navigator.of(context).pop();
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
      appBar: AppBar(
        title: Text(locale?.changePasswordLabel ?? 'Change Password'),
      ),
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
                      Text(locale?.changePasswordLabel ?? 'Change Password', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _currentCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'Current password',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: locale?.newPasswordLabel ?? 'New password',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: locale?.confirmPasswordLabel ?? 'Confirm password',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(locale?.changePasswordLabel ?? 'Change Password', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
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
