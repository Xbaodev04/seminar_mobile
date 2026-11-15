import 'package:just_audio/just_audio.dart';

import 'tts_engine.dart';

/// Boundaries for testing orchestration without platform plugins.
abstract class AudioOutput {
  Stream<void> get completed;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Duration get position;
  Duration? get duration;
  Future<void> load(String url);
  Future<void> play();
  Future<void> stop();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

class Mp3Output implements AudioOutput {
  final AudioPlayer _player = AudioPlayer();
  @override
  Stream<void> get completed => _player.playerStateStream
      .where((state) => state.processingState == ProcessingState.completed)
      .map((_) {});
  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  @override
  Duration get position => _player.position;
  @override
  Duration? get duration => _player.duration;
  @override
  Future<void> load(String url) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> dispose() => _player.dispose();
}

abstract class SpeechOutput {
  Stream<void> get completed;
  Future<void> speak(String text, String language);
  Future<void> stop();
}

class DeviceSpeechOutput implements SpeechOutput {
  @override
  Stream<void> get completed => TtsEngine.instance.onCompletion;
  @override
  Future<void> speak(String text, String language) =>
      TtsEngine.instance.speak(text: text, targetLang: language);
  @override
  Future<void> stop() => TtsEngine.instance.stop();
}
