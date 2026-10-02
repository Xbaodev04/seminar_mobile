import 'package:seminar_mobile/data/remote/api_client.dart';
import 'package:seminar_mobile/core/services/auth_service.dart';

class ListeningHistoryService {
  static final ListeningHistoryService instance = ListeningHistoryService._();
  ListeningHistoryService._();

  Future<Map<String, dynamic>> fetchHistory({
    required int page,
    required int size,
    int? fromTimestamp,
    int? toTimestamp,
    String? languageCode,
  }) async {
    final access = AuthService.instance.accessToken;
    if (access == null) {
      throw Exception('User is not authenticated');
    }

    return await ApiClient.instance.listListeningHistory(
      accessToken: access,
      page: page,
      size: size,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
      languageCode: languageCode,
    );
  }

  Future<Map<String, dynamic>> addHistory({
    required String stallId,
    required String stallContentId,
    required int listenedAt,
    int? listenDuration,
  }) async {
    final access = AuthService.instance.accessToken;
    if (access == null) {
      throw Exception('User is not authenticated');
    }

    return await ApiClient.instance.addListeningHistory(
      accessToken: access,
      stallId: stallId,
      stallContentId: stallContentId,
      listenedAt: listenedAt,
      listenDuration: listenDuration,
    );
  }
}
