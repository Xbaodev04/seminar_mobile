import 'package:flutter/material.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/presentation/widgets/app_toast.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/language_selector.dart';
import '../../core/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.fetchMeFromApi();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.user;
        
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.exitAppTitle),
                content: Text(AppLocalizations.of(context)!.exitAppConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context)!.cancelButton),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(AppLocalizations.of(context)!.exitButton),
                  ),
                ],
              ),
            );
          },
          child: Scaffold(
            extendBody: true,
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.profilePageTitle),
              automaticallyImplyLeading: false,
            ),
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          child: Icon(Icons.person, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.full_name ?? AppLocalizations.of(context)!.userLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user?.email ?? 'user@example.com',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withAlpha(178),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Settings merged into profile
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        leading: Icon(Icons.edit, color: colorScheme.onSurface),
                        title: Text(AppLocalizations.of(context)!.editProfileLabel),
                        onTap: () {
                          Navigator.of(context).pushNamed('/update_profile');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.lock, color: colorScheme.onSurface),
                        title: Text(AppLocalizations.of(context)!.changePasswordLabel),
                        onTap: () {
                          Navigator.of(context).pushNamed('/change_password');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.language, color: colorScheme.onSurface),
                        title: Text(
                          AppLocalizations.of(context)!.languageLabel,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        trailing: const LanguageSelector(),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.autoPlayTitle,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        value: true,
                        onChanged: (_) {},
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.allowNotificationsTitle,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        value: true,
                        onChanged: (_) {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurface,
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.versionLabel,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          '1.0.0',
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(178),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Theme.of(context).colorScheme.error,
                  elevation: 0,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await AuthService.instance.signOut();
                        AppToast.showSuccess(
                          context,
                          AppLocalizations.of(context)!.loggedOutMsg,
                        );
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.logoutLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: AppBottomNav(
              currentIndex: 1, // 0 for Home, 1 for Profile
              onTap: (index) {
                if (index == 0) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
          ),
        );
      },
    );
  }
}
