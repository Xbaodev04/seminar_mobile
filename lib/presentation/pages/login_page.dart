import 'package:flutter/material.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  void _showError(String msg) => AppToast.showError(context, msg);

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // Show success and navigate using captured objects
      messenger.hideCurrentSnackBar();
      AppToast.showSuccess(
        context,
        AppLocalizations.of(context)!.loginSuccessMsg,
      );
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      messenger.hideCurrentSnackBar();
      var s = e.toString();
      while (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
      AppToast.showError(context, s);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      messenger.hideCurrentSnackBar();
      AppToast.showSuccess(
        context,
        AppLocalizations.of(context)!.loginGoogleSuccessMsg,
      );
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      messenger.hideCurrentSnackBar();
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInDevice() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithDevice();
      messenger.hideCurrentSnackBar();
      AppToast.showSuccess(
        context,
        AppLocalizations.of(context)!.loginDeviceSuccessMsg,
      );
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      messenger.hideCurrentSnackBar();
      var s = e.toString();
      while (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
      AppToast.showError(context, s);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: kGrapGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        // Logo (PNG)
                        SizedBox(
                          width: 82,
                          height: 82,
                          child: Image.asset('lib/assets/imgs/favicon.png'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                    labelText: AppLocalizations.of(
                                      context,
                                    )!.emailLabel,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? AppLocalizations.of(
                                          context,
                                        )!.enterEmailMsg
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passCtrl,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    labelText: AppLocalizations.of(
                                      context,
                                    )!.passwordLabel,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? AppLocalizations.of(
                                          context,
                                        )!.enterPasswordMsg
                                      : null,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submitEmail,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    child: _loading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.loginButton,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.createAccountNew,
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _signInGoogle,
                              icon: Icon(
                                Icons.login,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.loginWithGoogle,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.tertiary.withAlpha(80),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _signInDevice,
                              icon: Icon(
                                Icons.phone_android,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.loginWithDevice,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
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
