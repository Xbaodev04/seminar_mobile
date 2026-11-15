import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';
import 'package:seminar_mobile/core/services/locale_provider.dart';
import 'package:seminar_mobile/l10n/app_localizations.dart';

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
      final isLanguageSelected = LocaleProvider.instance.isLanguageSelected;

      if (!isLanguageSelected) {
        // Chưa chọn ngôn ngữ -> Mở trang chọn ngôn ngữ
        Navigator.of(context).pushReplacementNamed('/language_selection');
      } else {
        // Đã chọn ngôn ngữ -> Kiểm tra đăng nhập
        final loggedIn = AuthService.instance.isLoggedIn;
        Navigator.of(
          context,
        ).pushReplacementNamed(loggedIn ? '/home' : '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/imgs/bg_food.jpg'),
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
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.splashSubtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
