import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:seminar_mobile/data/remote/localization_api.dart';
import 'package:seminar_mobile/engines/audio_output.dart';
import 'package:seminar_mobile/engines/audio_queue_manager.dart';
import 'package:seminar_mobile/engines/narration_audio_resolver.dart';

class FakeAudio implements AudioOutput {
  final events = StreamController<void>.broadcast(sync: true);
  final urls = <String>[];
  int plays = 0;
  bool failLoad = false;
  bool failPlay = false;
  Completer<void>? loading;
  Completer<void>? playing;
  @override
  Stream<void> get completed => events.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Duration get position => Duration.zero;
  @override
  Duration? get duration => const Duration(seconds: 60);
  @override
  Future<void> load(String url) async {
    urls.add(url);
    if (loading != null) await loading!.future;
    if (failLoad) throw StateError('Cannot load');
  }

  @override
  Future<void> play() async {
    plays++;
    if (failPlay) throw StateError('Cannot play');
    if (playing != null) await playing!.future;
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> dispose() => events.close();
}

class FakeSpeech implements SpeechOutput {
  final events = StreamController<void>.broadcast(sync: true);
  final calls = <(String, String)>[];
  @override
  Stream<void> get completed => events.stream;
  @override
  Future<void> speak(String text, String language) async {
    calls.add((text, language));
  }

  @override
  Future<void> stop() async {}
}

LocalizedNarration localized([String poi = 'poi-1']) => LocalizedNarration(
  poiId: poi,
  lang: 'en',
  title: 'English title',
  text: 'English text',
  audioUrl: 'http://localhost:8000/static/audio/$poi.mp3',
);

AudioRequest request({
  String poi = 'poi-1',
  bool fallback = true,
  String? url = '/static/audio/old.mp3',
  String sourceLang = 'vi',
  void Function(LocalizedNarration)? onLocalized,
  void Function()? onComplete,
}) => AudioRequest(
  poiId: poi,
  audioUrl: url,
  isFallback: fallback,
  sourceLang: sourceLang,
  fallbackText: 'Nội dung gốc',
  targetLang: 'en',
  onLocalized: onLocalized,
  onComplete: onComplete,
);

void main() {
  late FakeAudio audio;
  late FakeSpeech speech;
  late AudioQueueManager queue;
  late String language;
  late int apiCalls;
  late Future<LocalizedNarration> Function(String, String) generate;

  setUp(() {
    audio = FakeAudio();
    speech = FakeSpeech();
    language = 'en';
    apiCalls = 0;
    generate = (poi, lang) async => localized(poi);
    queue = AudioQueueManager(
      audio: audio,
      speech: speech,
      currentLanguage: () => language,
      resolver: NarrationAudioResolver(
        baseUrl: () => 'http://localhost:8000/api/v1',
        generate: (poi, lang) {
          apiCalls++;
          return generate(poi, lang);
        },
      ),
    );
  });
  tearDown(() async {
    queue.dispose();
    await speech.events.close();
  });

  test(
    'Tier 1 plays ready matching-language MP3 without calling backend',
    () async {
      await queue.enqueue(request(fallback: false, sourceLang: 'en'));
      expect(apiCalls, 0);
      expect(audio.urls.single, 'http://localhost:8000/static/audio/old.mp3');
      expect(audio.plays, 1);
      expect(speech.calls, isEmpty);
    },
  );

  test(
    'Tier 1.5 replaces fallback audio and reports translated content',
    () async {
      LocalizedNarration? update;
      await queue.enqueue(request(onLocalized: (result) => update = result));
      expect(apiCalls, 1);
      expect(update?.text, 'English text');
      expect(audio.urls.single, localized().audioUrl);
      expect(audio.plays, 1);
      expect(speech.calls, isEmpty);
    },
  );

  test(
    'missing URL triggers on-demand even when fallback flag is false',
    () async {
      await queue.enqueue(
        request(fallback: false, url: null, sourceLang: 'en'),
      );
      expect(apiCalls, 1);
      expect(audio.plays, 1);
    },
  );

  test(
    'language mismatch triggers on-demand even when flag is false',
    () async {
      await queue.enqueue(request(fallback: false));
      expect(apiCalls, 1);
      expect(audio.urls.single, localized().audioUrl);
    },
  );

  test(
    'backend failure uses source-language device TTS, never wrong-language MP3',
    () async {
      generate = (_, _) async =>
          throw const LocalizationFailure(statusCode: 503);
      await queue.enqueue(request());
      expect(audio.urls, isEmpty);
      expect(speech.calls.single, ('Nội dung gốc', 'vi'));
      expect(queue.isPreparing, isFalse);
    },
  );

  test('generated MP3 load failure uses translated text locally', () async {
    audio.failLoad = true;
    await queue.enqueue(request());
    expect(speech.calls.single, ('English text', 'en'));
  });

  test('asynchronous play failure also uses translated text locally', () async {
    audio.failPlay = true;
    await queue.enqueue(request());
    await Future<void>.delayed(Duration.zero);
    expect(speech.calls.single, ('English text', 'en'));
  });

  test('stop invalidates an in-flight backend response', () async {
    final pending = Completer<LocalizedNarration>();
    generate = (_, _) => pending.future;
    var updates = 0;
    final waiting = queue.enqueue(request(onLocalized: (_) => updates++));
    await Future<void>.delayed(Duration.zero);
    expect(queue.isPreparing, isTrue);
    await queue.stop();
    pending.complete(localized());
    await waiting;
    expect(audio.plays, 0);
    expect(speech.calls, isEmpty);
    expect(updates, 0);
  });

  test('switching POI discards delayed previous response', () async {
    final pending = Completer<LocalizedNarration>();
    generate = (poi, _) =>
        poi == 'poi-1' ? pending.future : Future.value(localized(poi));
    final old = queue.enqueue(request());
    await Future<void>.delayed(Duration.zero);
    await queue.enqueue(request(poi: 'poi-2'));
    pending.complete(localized());
    await old;
    expect(audio.urls, [localized('poi-2').audioUrl]);
    expect(audio.plays, 1);
  });

  test(
    'switching language discards delayed response including English',
    () async {
      final pending = Completer<LocalizedNarration>();
      generate = (_, _) => pending.future;
      final waiting = queue.enqueue(request());
      await Future<void>.delayed(Duration.zero);
      language = 'ja';
      await queue.stop();
      pending.complete(localized());
      await waiting;
      expect(audio.plays, 0);
      expect(speech.calls, isEmpty);
    },
  );

  test(
    'pause while generating does not auto-play when response arrives',
    () async {
      final pending = Completer<LocalizedNarration>();
      generate = (_, _) => pending.future;
      final waiting = queue.enqueue(request());
      await Future<void>.delayed(Duration.zero);
      await queue.pause();
      pending.complete(localized());
      await waiting;
      expect(audio.plays, 0);
      generate = (poi, _) async => localized(poi);
      await queue.resume();
      expect(audio.plays, 1);
    },
  );

  test(
    'pause/resume reuses generated URL without another API request',
    () async {
      await queue.enqueue(request());
      await queue.pause();
      await queue.resume();
      expect(apiCalls, 1);
      expect(audio.urls.length, 1);
      expect(audio.plays, 2);
    },
  );

  test('a delayed native load cannot replace the newer POI source', () async {
    final gate = Completer<void>();
    audio.loading = gate;
    final first = queue.enqueue(request());
    await Future<void>.delayed(Duration.zero);
    expect(audio.urls, [localized().audioUrl]);
    final second = queue.enqueue(request(poi: 'poi-2'));
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await Future.wait([first, second]);
    expect(audio.urls, [localized().audioUrl, localized('poi-2').audioUrl]);
    expect(audio.plays, 1);
  });

  test(
    'enqueue completes without waiting for the whole MP3 to finish',
    () async {
      audio.playing = Completer<void>();
      await queue.enqueue(request()).timeout(const Duration(seconds: 1));
      expect(queue.isPlaying, isTrue);
      audio.playing!.complete();
    },
  );

  test(
    'completion callback is delivered once and stop cannot resume old audio',
    () async {
      var completions = 0;
      await queue.enqueue(request(onComplete: () => completions++));
      audio.events.add(null);
      audio.events.add(null);
      expect(completions, 1);
      await queue.stop();
      await queue.resume();
      expect(audio.plays, 1);
    },
  );
}
