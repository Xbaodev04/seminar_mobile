import '../data/remote/localization_api.dart';

class ResolvedNarration {
  final String? audioUrl;
  final String text;
  final String language;
  final LocalizedNarration? localization;

  const ResolvedNarration({
    this.audioUrl,
    required this.text,
    required this.language,
    this.localization,
  });
}

/// Tier 1 -> Tier 1.5. A failure leaves source text for device TTS.
class NarrationAudioResolver {
  NarrationAudioResolver({required this.baseUrl, required this.generate});
  final String Function() baseUrl;
  final Future<LocalizedNarration> Function(String poiId, String lang) generate;

  Future<ResolvedNarration?> resolve({
    required String? poiId,
    required String? audioUrl,
    required bool isFallback,
    required String text,
    required String targetLang,
    required String? sourceLang,
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent()) return null;
    final matchingLanguage = sourceLang == null || sourceLang == targetLang;
    if (!isFallback &&
        matchingLanguage &&
        audioUrl != null &&
        audioUrl.trim().isNotEmpty) {
      try {
        return ResolvedNarration(
          audioUrl: resolveAudioUrl(baseUrl(), audioUrl),
          text: text,
          language: targetLang,
        );
      } on FormatException {
        // An unusable Tier 1 URL can be replaced by on-demand audio.
      }
    }
    if (poiId != null && poiId.isNotEmpty) {
      try {
        final localized = await generate(poiId, targetLang);
        if (!isCurrent()) return null;
        return ResolvedNarration(
          audioUrl: localized.audioUrl,
          text: localized.text,
          language: localized.lang,
          localization: localized,
        );
      } catch (_) {
        // Do not retry in a loop or play fallback audio in another language.
      }
    }
    if (!isCurrent()) return null;
    return ResolvedNarration(text: text, language: sourceLang ?? targetLang);
  }
}
