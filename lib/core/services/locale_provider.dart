import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../engines/narration_engine.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  static const _prefsKey = 'selected_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  String get effectiveLanguageCode {
    final code =
        _locale?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return supportedLocales.any((locale) => locale.languageCode == code)
        ? code
        : 'vi';
  }

  // Thêm biến cờ để biết người dùng đã từng chọn ngôn ngữ chưa
  bool _isLanguageSelected = false;
  bool get isLanguageSelected => _isLanguageSelected;

  List<Locale> get supportedLocales => const [
    Locale('vi'),
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('ko'),
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _isLanguageSelected = prefs.containsKey(_prefsKey);
    if (code == null || code.isEmpty) {
      _locale = null; // system default
    } else {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    _isLanguageSelected = true;
    // Invalidate pending audio before preferences IO can yield to an old request.
    await NarrationEngine.instance.leavePoi();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }

    // Yêu cầu: Đổi ngôn ngữ giữa chừng thì phải HỦY toàn bộ tiến trình đọc hiện tại
    // Gọi leavePoi() sẽ Stop Audio/TTS lập tức,
    // Ghi nhận lịch sử số giây đã nghe tới thời điểm hiện tại,
    // Và xóa sạch danh sách bài chờ (vì danh sách cũ chứa bản dịch của ngôn ngữ cũ).

    notifyListeners();
  }
}
