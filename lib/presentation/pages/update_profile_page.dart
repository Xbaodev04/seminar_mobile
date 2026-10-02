import 'package:flutter/material.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _avatarCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.user;

    _nameCtrl = TextEditingController(text: user?.full_name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: AuthService.instance.me?['phone'] as String? ?? '');
    _avatarCtrl = TextEditingController(text: AuthService.instance.me?['avatar_url'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.updateProfile(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
      );

      AppToast.showSuccess(
        context,
        locale?.updateProfileSuccess ?? 'Profile updated successfully',
      );
      Navigator.of(context).pop();
    } catch (e) {
      var msg = e.toString();
      while (msg.startsWith('Exception: ')) msg = msg.substring('Exception: '.length);
      AppToast.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale?.editProfileLabel ?? 'Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locale?.editProfileLabel ?? 'Edit Profile',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: locale?.fullNameLabel ?? 'Full name',
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return locale?.enterNameMsg ?? 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: locale?.emailLabel ?? 'Email',
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return locale?.enterEmailMsg ?? 'Please enter your email';
                            }
                            final email = value.trim();
                            if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) {
                                return locale?.invalidEmailMsg ?? 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: InputDecoration(
                            labelText: locale?.phoneLabel ?? 'Phone',
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _avatarCtrl,
                          decoration: InputDecoration(
                            labelText: locale?.avatarUrlLabel ?? 'Avatar URL',
                            prefixIcon: const Icon(Icons.link),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(locale?.saveButtonLabel ?? 'Save'),
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
      ),
    );
  }
}
