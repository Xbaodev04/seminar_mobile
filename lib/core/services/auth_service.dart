import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seminar_mobile/core/services/online_status_service.dart';
import 'package:seminar_mobile/data/remote/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String? email;
  final String? full_name;

  UserProfile({required this.id, this.email, this.full_name});

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': full_name,
  };

  factory UserProfile.fromJson(Map<String, dynamic> js) => UserProfile(
    id: js['id'] as String,
    email: js['email'] as String?,
    full_name: js['full_name'] as String?,
  );
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();

  AuthService._();

  static const _kUserKey = 'auth_user';
  static const _kAccessTokenKey = 'auth_access_token';
  static const _kRefreshTokenKey = 'auth_refresh_token';
  static const _kDeviceIdKey = 'auth_device_id';
  static const _kApiBaseUrl = 'http://10.0.2.2:8000';

  UserProfile? _user;
  UserProfile? get user => _user;

  bool get isLoggedIn => _user != null;

  late SharedPreferences _prefs;
  late String _deviceId;
  OnlineStatusService? _onlineStatusService;

  OnlineStatusService? get onlineStatusService => _onlineStatusService;
  bool get isOnlineConnected => _onlineStatusService?.isConnected ?? false;
  int get onlineCount => _onlineStatusService?.onlineCount ?? 0;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Get or create device ID
    _deviceId = _prefs.getString(_kDeviceIdKey) ?? '';
    if (_deviceId.isEmpty) {
      await _initDeviceId();
    }

    final s = _prefs.getString(_kUserKey);
    if (s != null) {
      try {
        final js = Map<String, dynamic>.from(jsonDecode(s));
        _user = UserProfile.fromJson(js);
      } catch (_) {}
    }
    if (kDebugMode) {
      await _ensureMockUsers();
    }
    // If we have tokens stored, try to refresh user from API
    final access = _prefs.getString(_kAccessTokenKey);
    final refresh = _prefs.getString(_kRefreshTokenKey);
    if (access != null) {
      try {
        final me = await ApiClient.instance.me(access);
        _me = me;
        _user = _profileFromMe(me);
        await _saveUserToPrefs();
        // Connect to online status WebSocket if we have a device ID
        if (_deviceId.isNotEmpty) {
          _connectToOnlineStatus(
            userId: int.tryParse(me['id']?.toString() ?? ''),
          );
        }
      } catch (e) {
        // Try refresh if available
        if (refresh != null) {
          try {
            final tokens = await ApiClient.instance.refresh(refresh);
            await _storeTokens(
              tokens['accessToken'] as String,
              tokens['refreshToken'] as String,
            );
            final me2 = await ApiClient.instance.me(
              tokens['accessToken'] as String,
            );
            _me = me2;
            _user = _profileFromMe(me2);
            await _saveUserToPrefs();
            // Connect to online status WebSocket
            if (_deviceId.isNotEmpty) {
              _connectToOnlineStatus(
                userId: int.tryParse(me2['id']?.toString() ?? ''),
              );
            }
          } catch (_) {
            // ignore
          }
        }
      }
    }

    notifyListeners();
  }

  /// Initialize device ID on first run
  Future<void> _initDeviceId() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? iosInfo.name;
      } else {
        deviceId = 'unknown_device';
      }

      _deviceId = deviceId;
      await _prefs.setString(_kDeviceIdKey, deviceId);
    } catch (e) {
      print('Error initializing device ID: $e');
      _deviceId = 'unknown_device';
    }
  }

  /// Public method: Connect to online status WebSocket when app opens
  /// This counts as "app access" - called when app launches, before login
  Future<void> connectToAppOnlineStatus() async {
    if (_deviceId.isEmpty) return;

    // If already connected, skip
    if (_onlineStatusService?.isConnected ?? false) return;

    try {
      print('📱 Connecting to online status (app access)');
      _onlineStatusService = OnlineStatusService(
        baseUrl: _kApiBaseUrl,
        deviceId: _deviceId,
      );
      _onlineStatusService!.addListener(() {
        notifyListeners();
      });
      // Connect without user_id initially - counts as app access
      await _onlineStatusService!.connect(
        userId: isLoggedIn ? int.tryParse(user?.id ?? '') : null,
      );
      print('✓ Connected to online status');
      notifyListeners();
    } catch (e) {
      print('Error connecting to online status: $e');
    }
  }

  /// Private method: Connect to online status WebSocket (used during login)
  void _connectToOnlineStatus({int? userId}) {
    if (_deviceId.isEmpty) return;

    try {
      // If not already connected, create new service
      if (_onlineStatusService == null) {
        _onlineStatusService = OnlineStatusService(
          baseUrl: _kApiBaseUrl,
          deviceId: _deviceId,
        );
        _onlineStatusService!.addListener(() {
          notifyListeners();
        });
      }

      // Update user_id if logging in
      _onlineStatusService!.connect(userId: userId);
    } catch (e) {
      print('Error connecting to online status: $e');
    }
  }

  /// Disconnect from online status WebSocket
  Future<void> _disconnectFromOnlineStatus() async {
    if (_onlineStatusService != null) {
      _onlineStatusService!.removeListener(() {});
      await _onlineStatusService!.disconnect();
      _onlineStatusService = null;
    }
  }

  /// Register via remote API. On success stores tokens and user profile.
  /// Start registration: sends OTP to email. Does not log the user in.
  Future<void> register({
    String? username,
    required String email,
    required String password,
    required String full_name,
  }) async {
    try {
      await ApiClient.instance.register(
        username: username,
        full_name: full_name,
        email: email,
        password: password,
      );
      // Register only sends OTP now; client should show verification UI.
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP and complete registration. On success stores tokens and fetches profile.
  Future<void> verifyAndComplete({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await ApiClient.instance.verify(email: email, otp: otp);
      final access = res['accessToken'] as String?;
      final refresh = res['refreshToken'] as String?;
      if (access == null || refresh == null)
        throw Exception('Verify failed: missing tokens');
      await _storeTokens(access, refresh);
      final me = await ApiClient.instance.me(access);
      _me = me;
      _user = _profileFromMe(me);
      await _saveUserToPrefs();
      // Connect to online status
      if (_deviceId.isNotEmpty) {
        _connectToOnlineStatus(
          userId: int.tryParse(me['id']?.toString() ?? ''),
        );
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset (sends OTP to email)
  Future<void> forgotPassword({required String email}) async {
    try {
      await ApiClient.instance.forgotPassword(email: email);
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP and reset password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await ApiClient.instance.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Change current user password (requires auth token)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final access = accessToken;
    if (access == null) {
      throw Exception('User is not authenticated');
    }
    try {
      await ApiClient.instance.changePassword(
        accessToken: access,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile data
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    final access = accessToken;
    if (access == null) {
      throw Exception('User is not authenticated');
    }

    try {
      final result = await ApiClient.instance.updateProfile(
        accessToken: access,
        fullName: fullName,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      final data = result['data'] as Map<String, dynamic>?;
      if (data != null) {
        _me = data;
        _user = _profileFromMe(data);
        await _saveUserToPrefs();
        notifyListeners();
      }

      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in using remote API
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.instance.login(
        email: email,
        password: password,
      );
      final access = res['accessToken'] as String?;
      final refresh = res['refreshToken'] as String?;
      if (access == null || refresh == null)
        throw Exception('Login failed: missing tokens');
      await _storeTokens(access, refresh);
      final me = await ApiClient.instance.me(access);
      _me = me;
      _user = _profileFromMe(me);
      await _saveUserToPrefs();
      // Connect to online status
      if (_deviceId.isNotEmpty) {
        _connectToOnlineStatus(
          userId: int.tryParse(me['id']?.toString() ?? ''),
        );
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Returns stored access token (if any)
  String? get accessToken => _prefs.getString(_kAccessTokenKey);

  /// Public method to refresh tokens - used by HTTP client interceptor
  Future<bool> refreshAccessToken() async {
    try {
      final refresh = _prefs.getString(_kRefreshTokenKey);
      if (refresh == null) return false;

      final res = await ApiClient.instance.refresh(refresh);
      final access = res['accessToken'] as String?;
      final newRefresh = res['refreshToken'] as String?;

      if (access == null || newRefresh == null) return false;

      await _storeTokens(access, newRefresh);
      return true;
    } catch (_) {
      // Refresh failed - log out the user
      await signOut();
      return false;
    }
  }

  /// Get refresh token (used by HTTP client)
  String? getRefreshToken() => _prefs.getString(_kRefreshTokenKey);

  // --- Subscription helpers -------------------------------------------------
  Map<String, dynamic>? _me;
  Map<String, dynamic>? get me => _me;

  Future<void> fetchMeFromApi() async {
    final access = _prefs.getString(_kAccessTokenKey);
    if (access == null) return;
    try {
      final current = await ApiClient.instance.me(access);
      _me = current;
      _user = _profileFromMe(current);
      await _saveUserToPrefs();
      notifyListeners();
    } catch (_) {
      // ignore network/errors here
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('[GoogleSignIn] Initializing with serverClientId...');
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '272475900321-l35p89k13uognv3vepb079jggk296p10.apps.googleusercontent.com',
      );
      debugPrint('[GoogleSignIn] Authenticating...');
      final acc = await GoogleSignIn.instance.authenticate();
      debugPrint('[GoogleSignIn] Account authenticated: ${acc.email}');

      final auth = await acc.authentication;
      final idToken = auth.idToken;
      debugPrint(
        '[GoogleSignIn] ID Token: ${idToken != null ? "received (${idToken.length} chars)" : "null"}',
      );

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Không thể lấy Google ID token. Vui lòng kiểm tra lại serverClientId',
        );
      }

      // Send to backend for authentication
      debugPrint('[GoogleSignIn] Sending ID token to backend...');
      final res = await ApiClient.instance.googleLogin(idToken: idToken);
      final access = res['accessToken'] as String?;
      final refresh = res['refreshToken'] as String?;

      if (access == null || refresh == null) {
        throw Exception(
          'Đăng nhập Google thất bại: Không nhận được token từ server',
        );
      }

      await _storeTokens(access, refresh);
      final me = await ApiClient.instance.me(access);
      _me = me;
      _user = _profileFromMe(me);
      await _saveUserToPrefs();
      // Connect to online status
      if (_deviceId.isNotEmpty) {
        _connectToOnlineStatus(
          userId: int.tryParse(me['id']?.toString() ?? ''),
        );
      }
      notifyListeners();
      debugPrint('[GoogleSignIn] Google sign in SUCCESS!');
    } catch (e, stack) {
      debugPrint('[GoogleSignIn] ERROR: $e');
      debugPrint('[GoogleSignIn] STACK: $stack');
      rethrow;
    }
  }

  Future<void> signInWithDevice() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? iosInfo.name;
      } else {
        throw Exception('Unsupported platform');
      }

      final res = await ApiClient.instance.loginDevice(deviceId: deviceId);
      final access = res['accessToken'] as String?;
      final refresh = res['refreshToken'] as String?;

      if (access == null || refresh == null)
        throw Exception('Device login failed: missing tokens');

      await _storeTokens(access, refresh);
      final me = await ApiClient.instance.me(access);
      _me = me;
      _user = _profileFromMe(me);
      await _saveUserToPrefs();

      // Store device ID
      _deviceId = deviceId;
      await _prefs.setString(_kDeviceIdKey, deviceId);

      // Connect to online status
      if (_deviceId.isNotEmpty) {
        _connectToOnlineStatus(
          userId: int.tryParse(me['id']?.toString() ?? ''),
        );
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Disconnect from online status before signing out
    await _disconnectFromOnlineStatus();

    _user = null;
    await _prefs.remove(_kUserKey);
    await _prefs.remove(_kAccessTokenKey);
    await _prefs.remove(_kRefreshTokenKey);
    // Also sign out from Google if needed
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveUserToPrefs() async {
    if (_user == null) return;
    await _prefs.setString(_kUserKey, jsonEncode(_user!.toJson()));
  }

  Future<void> _storeTokens(String access, String refresh) async {
    await _prefs.setString(_kAccessTokenKey, access);
    await _prefs.setString(_kRefreshTokenKey, refresh);
  }

  UserProfile _profileFromMe(Map<String, dynamic> me) {
    // id may be at top-level or nested under 'user'
    final id =
        me['id']?.toString() ??
        (me['user'] is Map ? (me['user']['id']?.toString()) : null) ??
        'unknown';
    final email =
        me['email'] as String? ??
        (me['user'] is Map ? me['user']['email'] as String? : null);
    String? full_name = me['full_name'] as String?;
    if (full_name == null && me['user'] is Map) {
      full_name =
          me['user']['username'] as String? ?? me['user']['email'] as String?;
    }
    full_name ??= me['username'] as String?;
    return UserProfile(id: id, email: email, full_name: full_name);
  }

  String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

  // Debug helper: ensure a demo user exists so you can test login quickly
  Future<void> _ensureMockUsers() async {
    // Note: keep existing local demo users for convenience in development
    final usersKey = 'registered_users';
    final users = _prefs.getStringList(usersKey) ?? <String>[];
    var found = false;
    for (final u in users) {
      final m = Map<String, dynamic>.from(jsonDecode(u));
      if (m['email'] == 'demo@grap.dev') {
        found = true;
        break;
      }
    }
    if (!found) {
      final demo = {
        'id': 'demo',
        'email': 'demo@grap.dev',
        'full_name': 'Demo User',
        'password': _sha256('password123'),
      };
      users.add(jsonEncode(demo));
      await _prefs.setStringList(usersKey, users);
    }
  }

  // Quick demo login (convenience for development)
  Future<void> quickLoginDemo() async {
    // If API fails or not configured, fallback to local demo
    try {
      await signInWithEmail(email: 'demo@grap.dev', password: 'password123');
    } catch (_) {
      final users = _prefs.getStringList('registered_users') ?? <String>[];
      final pwdHash = _sha256('password123');
      for (final u in users) {
        final m = Map<String, dynamic>.from(jsonDecode(u));
        if (m['email'] == 'demo@grap.dev' && m['password'] == pwdHash) {
          _user = UserProfile(
            id: m['id'] as String,
            email: m['email'] as String?,
            full_name: m['full_name'] as String?,
          );
          await _saveUserToPrefs();
          notifyListeners();
          return;
        }
      }
      throw Exception('Demo login failed');
    }
  }
}
