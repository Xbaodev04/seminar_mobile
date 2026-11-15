import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A random installation ID, not Android's shared OS build identifier.
class InstallationIdentity {
  static const storageKey = 'auth_installation_id_v1';

  static Future<String> loadOrCreate(SharedPreferences prefs) async {
    var id = prefs.getString(storageKey);
    if (id == null || id.isEmpty) {
      final random = Random.secure();
      id =
          'install_${base64UrlEncode(List.generate(32, (_) => random.nextInt(256))).replaceAll('=', '')}';
      if (!await prefs.setString(storageKey, id)) {
        throw StateError('Không thể lưu mã đăng nhập trên thiết bị');
      }
    }
    await prefs.setString('auth_device_id', id);
    return id;
  }
}
