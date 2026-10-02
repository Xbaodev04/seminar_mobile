import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/core/services/locale_provider.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';

import 'presentation/pages/change_password_page.dart';
import 'presentation/pages/forgot_password_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/profile_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/update_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await LocaleProvider.instance.init();
  } catch (e) {
    debugPrint('Error initializing LocaleProvider: $e');
  }

  try {
    await AuthService.instance.init();
  } catch (e) {
    debugPrint('Error initializing AuthService: $e');
  }

  try {
    await AuthService.instance.connectToAppOnlineStatus();
  } catch (e) {
    debugPrint('Error connecting online status: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    LocaleProvider.instance.addListener(_onLocaleChanged);
    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLocaleChanged);
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authService = AuthService.instance;

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - ensure WebSocket is connected
        debugPrint('✓ App resumed - ensuring online status is active');
        if (authService.onlineStatusService?.isConnected == false) {
          try {
            authService.connectToAppOnlineStatus();
          } catch (_) {}
        }
        break;

      case AppLifecycleState.paused:
        debugPrint('⏸ App paused - keeping online status active');
        break;

      case AppLifecycleState.detached:
        debugPrint('✗ App detached');
        break;

      case AppLifecycleState.hidden:
        debugPrint('🔽 App hidden');
        break;

      case AppLifecycleState.inactive:
        debugPrint('⚠ App inactive');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Title is provided by localization
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: LocaleProvider.instance.locale,
      debugShowCheckedModeBanner: false,
      theme: grapTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash': (ctx) => const SplashPage(),
        '/home': (ctx) => const HomePage(),
        '/login': (ctx) => const LoginPage(),
        '/register': (ctx) => const RegisterPage(),
        '/forgot': (ctx) => const ForgotPasswordPage(),
        '/profile': (ctx) => const ProfilePage(),
        '/change_password': (ctx) => const ChangePasswordPage(),
        '/update_profile': (ctx) => const UpdateProfilePage(),
      },
    );
  }
}
