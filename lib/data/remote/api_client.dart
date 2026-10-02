import 'auth_api.dart';
import 'poi_api.dart';

class ApiClient {
  ApiClient._private();
  static final ApiClient instance = ApiClient._private();

  /// Set this to your running API address. For Android emulator use 10.0.2.2
  String baseUrl = const String.fromEnvironment(
    'SEMINAR_API_BASE',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => AuthApi.instance.login(email: email, password: password);

  Future<Map<String, dynamic>> listListeningHistory({
    required String accessToken,
    int page = 1,
    int size = 20,
    int? fromTimestamp,
    int? toTimestamp,
    String? languageCode,
  }) => AuthApi.instance.listListeningHistory(
    accessToken: accessToken,
    page: page,
    size: size,
    fromTimestamp: fromTimestamp,
    toTimestamp: toTimestamp,
    languageCode: languageCode,
  );

  Future<Map<String, dynamic>> addListeningHistory({
    required String accessToken,
    required String stallId,
    required String stallContentId,
    required int listenedAt,
    int? listenDuration,
  }) => AuthApi.instance.addListeningHistory(
    accessToken: accessToken,
    stallId: stallId,
    stallContentId: stallContentId,
    listenedAt: listenedAt,
    listenDuration: listenDuration,
  );

  Future<Map<String, dynamic>> register({
    String? username,
    required String email,
    required String password,
    required String full_name,
  }) => AuthApi.instance.register(
    username: username,
    email: email,
    password: password,
    full_name: full_name,
  );

  Future<Map<String, dynamic>> verify({
    required String email,
    required String otp,
  }) => AuthApi.instance.verify(email: email, otp: otp);

  Future<Map<String, dynamic>> forgotPassword({required String email}) =>
      AuthApi.instance.forgotPassword(email: email);

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) => AuthApi.instance.resetPassword(
    email: email,
    otp: otp,
    newPassword: newPassword,
  );

  Future<Map<String, dynamic>> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) => AuthApi.instance.changePassword(
    accessToken: accessToken,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) => AuthApi.instance.updateProfile(
    accessToken: accessToken,
    fullName: fullName,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
  );

  Future<Map<String, dynamic>> me(String accessToken) =>
      AuthApi.instance.me(accessToken);

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      AuthApi.instance.refresh(refreshToken);

  Future<Map<String, dynamic>> googleLogin({required String idToken}) =>
      AuthApi.instance.googleLogin(idToken: idToken);

  Future<Map<String, dynamic>> loginDevice({required String deviceId}) =>
      AuthApi.instance.loginDevice(deviceId: deviceId);

  Future<List<Map<String, dynamic>>> listStalls(
    String accessToken, {
    String? search,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) => PoiApi.instance.listStalls(
    accessToken,
    search: search,
    latitude: latitude,
    longitude: longitude,
    limit: limit,
    offset: offset,
  );

  Future<List<Map<String, dynamic>>> getStallContents(
    String stallId,
    String accessToken,
  ) => PoiApi.instance.getStallContents(stallId, accessToken);

  Future<Map<String, dynamic>?> getStall(String stallId, String accessToken) =>
      PoiApi.instance.getStall(stallId, accessToken);
}
