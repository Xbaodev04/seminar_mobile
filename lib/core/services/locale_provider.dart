import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  static const _prefsKey = 'selected_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  List<Locale> get supportedLocales => const [
        Locale('en'),
        Locale('vi'),
        Locale('zh'),
        Locale('ko'),
      ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null || code.isEmpty) {
      _locale = null; // system default
    } else {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    notifyListeners();
  }
}
