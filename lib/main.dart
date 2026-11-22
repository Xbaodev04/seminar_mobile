import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/core/services/locale_provider.dart';
import 'core/services/visitor_analytics.dart';
import 'package:seminar_mobile/core/theme/grap_theme.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';

import 'presentation/pages/change_password_page.dart';
import 'presentation/pages/forgot_password_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/language_selection_page.dart';
import 'presentation/pages/listening_history_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/profile_page.dart';
import 'presentation/pages/qr_scan_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/update_profile_page.dart';
import 'presentation/pages/poi_link_page.dart';
import 'core/navigation/poi_link.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Xử lý lỗi
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // TẢI SONG SONG (PARALLEL LOAD) CÁC DỊCH VỤ CẦN THIẾT
  try {
    await Future.wait([
      LocaleProvider.instance.init(),
      AuthService.instance.init(
        restoreSession: !(kIsWeb && isPoiLocation(Uri.base.toString())),
      ),
      VisitorAnalytics.instance.init(),
    ]);
  } catch (e) {
    debugPrint('Error during Parallel Load: $e');
  }

  // Kết nối socket sau khi Auth đã load xong token
  try {
    unawaited(AuthService.instance.connectToAppOnlineStatus());
  } catch (e) {
    debugPrint('Error connecting online status: $e');
  }

  unawaited(VisitorAnalytics.instance.startVisit());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialLocation});
  final String? initialLocation;

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
        unawaited(authService.setAppActive(true));
        unawaited(VisitorAnalytics.instance.flush());
        unawaited(VisitorAnalytics.instance.startVisit());
        break;

      case AppLifecycleState.paused:
        unawaited(authService.setAppActive(false));
        unawaited(VisitorAnalytics.instance.flush());
        break;

      case AppLifecycleState.detached:
        unawaited(authService.setAppActive(false));
        break;

      case AppLifecycleState.hidden:
        unawaited(authService.setAppActive(false));
        break;

      case AppLifecycleState.inactive:
        debugPrint('⚠ App inactive');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => Listener(
        onPointerDown: (_) => VisitorAnalytics.instance.recordActivity(),
        onPointerSignal: (_) => VisitorAnalytics.instance.recordActivity(),
        child: child ?? const SizedBox.shrink(),
      ),
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
      initialRoute:
          widget.initialLocation ??
          (kIsWeb ? _webInitialLocation() : '/splash'),
      onGenerateInitialRoutes: (location) => [
        MaterialPageRoute(
          settings: RouteSettings(name: location),
          builder: (_) => isPoiLocation(location)
              ? PoiLinkPage(
                  poiId: poiIdFromLocation(location),
                  fromQr: isQrLocation(location),
                )
              : const SplashPage(),
        ),
      ],
      onGenerateRoute: (settings) => isPoiLocation(settings.name ?? '')
          ? MaterialPageRoute(
              settings: settings,
              builder: (_) => PoiLinkPage(
                poiId: poiIdFromLocation(settings.name!),
                fromQr: isQrLocation(settings.name!),
              ),
            )
          : null,
      routes: {
        '/splash': (ctx) => const SplashPage(),
        '/language_selection': (ctx) => const LanguageSelectionPage(),
        '/home': (ctx) => const HomePage(),
        '/login': (ctx) => const LoginPage(),
        '/register': (ctx) => const RegisterPage(),
        '/forgot': (ctx) => const ForgotPasswordPage(),
        '/profile': (ctx) => const ProfilePage(),
        '/change_password': (ctx) => const ChangePasswordPage(),
        '/update_profile': (ctx) => const UpdateProfilePage(),
        '/listening_history': (ctx) => const ListeningHistoryPage(),
        '/qr_scan': (ctx) => const QrScanPage(),
      },
    );
  }

  String _webInitialLocation() {
    final uri = Uri.base;
    final location = uri.fragment.startsWith('/')
        ? uri.fragment
        : Uri(
            path: uri.path,
            query: uri.hasQuery ? uri.query : null,
          ).toString();
    return isPoiLocation(location) ? location : '/splash';
  }
}
