import 'package:flutter/foundation.dart';

import '../../data/models/poi.dart';
import '../../engines/audio_queue_manager.dart';
import '../../engines/narration_engine.dart';

/// Legacy alias, completely delegates to NarrationEngine and AudioQueueManager
class GeoAudioManager extends ChangeNotifier {
  GeoAudioManager._private() {
    NarrationEngine.instance.addListener(() {
      notifyListeners();
    });
  }
  static final GeoAudioManager instance = GeoAudioManager._private();

  Poi? get currentPoi => NarrationEngine.instance.currentPoi;
  bool get isPlaying => NarrationEngine.instance.isPlaying;
  bool get isPreparing => NarrationEngine.instance.isPreparing;
  List<Map<String, dynamic>> get currentContents =>
      NarrationEngine.instance.currentContents;
  int get currentContentIndex => NarrationEngine.instance.currentContentIndex;

  Future<void> enterPoi(
    Poi poi, {
    String? language,
    List<Map<String, dynamic>>? initialContents,
    bool autoPlay = false,
  }) async {
    await NarrationEngine.instance.enterPoi(
      poi,
      initialContents: initialContents,
      autoPlay: autoPlay,
    );
  }

  Future<void> playContent(int index) async =>
      NarrationEngine.instance.playContent(index);
  Future<void> playNextContent() async =>
      NarrationEngine.instance.playNextContent();
  Future<void> togglePlay() async => NarrationEngine.instance.togglePlay();
  Future<void> leavePoi() async => NarrationEngine.instance.leavePoi();

  Map<String, dynamic>? get currentContent =>
      NarrationEngine.instance.currentContent;
  String get currentTitle => NarrationEngine.instance.currentTitle;

  Stream<Duration> get positionStream =>
      AudioQueueManager.instance.positionStream;
  Stream<Duration?> get durationStream =>
      AudioQueueManager.instance.durationStream;
  Duration get currentPosition => AudioQueueManager.instance.currentPosition;
  Duration? get currentDuration => AudioQueueManager.instance.currentDuration;

  Future<void> seek(Duration position) async =>
      AudioQueueManager.instance.seek(position);
  Future<void> seekForward({int seconds = 10}) async =>
      AudioQueueManager.instance.seekForward(seconds: seconds);
  Future<void> seekBackward({int seconds = 10}) async =>
      AudioQueueManager.instance.seekBackward(seconds: seconds);
}
