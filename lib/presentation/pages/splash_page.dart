import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      final loggedIn = AuthService.instance.isLoggedIn;
      Navigator.of(context).pushReplacementNamed(loggedIn ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/imgs/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(115),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.headset, size: 96, color: Colors.white),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.appTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.splashSubtitle, style: const TextStyle(color: Colors.white70))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
