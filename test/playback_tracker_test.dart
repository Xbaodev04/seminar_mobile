import 'package:flutter_test/flutter_test.dart';
import 'package:seminar_mobile/engines/playback_tracker.dart';

void main() {
  late List<Map<String, dynamic>> events;
  late PlaybackTracker tracker;
  late DateTime now;
  setUp(() {
    events = [];
    now = DateTime.utc(2026, 11, 11);
    tracker = PlaybackTracker(emit: events.add, now: () => now);
    tracker.prepare('012345678901234567890123', 'en');
  });

  test('buffering or failure before playback does not count as a listen', () {
    tracker.audioPosition(Duration.zero);
    tracker.finish(completed: false);
    expect(events, isEmpty);
  });

  test('pause/resume shares one playback ID and excludes seek distance', () {
    tracker.audioPosition(const Duration(seconds: 2));
    tracker.pause();
    tracker.audioResumed(const Duration(seconds: 2));
    tracker.audioPosition(const Duration(seconds: 3));
    tracker.seekTo(const Duration(seconds: 50));
    tracker.audioPosition(const Duration(seconds: 51));
    tracker.finish(completed: true);
    tracker.finish(completed: true);
    expect(events.map((e) => e['kind']), ['audio_started', 'audio_completed']);
    expect(events.first['playback_id'], events.last['playback_id']);
    expect(events.last['duration_seconds'], 4);
  });

  test('device speech fallback retains identity and excludes paused time', () {
    tracker.audioPosition(const Duration(seconds: 1));
    tracker.speechStarted();
    now = now.add(const Duration(seconds: 3));
    tracker.pause();
    now = now.add(const Duration(seconds: 20));
    tracker.speechStarted();
    now = now.add(const Duration(seconds: 2));
    tracker.finish(completed: false);
    expect(events.map((e) => e['kind']), ['audio_started', 'audio_ended']);
    expect(events.last['duration_seconds'], 6);
    expect(events.first['playback_id'], events.last['playback_id']);
  });

  test(
    'new language creates new playback identity and uses actual fallback language',
    () {
      tracker.audioPosition(const Duration(seconds: 1));
      tracker.prepare('012345678901234567890123', 'vi');
      tracker.speechStarted();
      tracker.finish(completed: true);
      expect(events.map((e) => e['kind']), [
        'audio_started',
        'audio_ended',
        'audio_started',
        'audio_completed',
      ]);
      expect(events[0]['playback_id'], isNot(events[2]['playback_id']));
      expect(events[2]['language'], 'vi');
    },
  );

  test(
    'consent granted mid-playback starts counting with next playback only',
    () {
      var enabled = false;
      var version = 0;
      tracker = PlaybackTracker(
        emit: events.add,
        isEnabled: () => enabled,
        consentVersion: () => version,
      );
      tracker.prepare('012345678901234567890123', 'en');
      tracker.audioPosition(const Duration(seconds: 1));
      enabled = true;
      version++;
      tracker.finish(completed: true);
      expect(events, isEmpty);
      tracker.prepare('012345678901234567890123', 'en');
      tracker.speechStarted();
      tracker.finish(completed: true);
      expect(events.length, 2);
    },
  );

  test('UUID and anonymous payload match backend validation', () {
    tracker.speechStarted();
    now = now.add(const Duration(seconds: 2));
    tracker.finish(completed: true);
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    for (final event in events) {
      expect(uuid.hasMatch(event['event_id']), isTrue);
      expect(uuid.hasMatch(event['playback_id']), isTrue);
      expect(DateTime.parse(event['occurred_at']).isUtc, isTrue);
      expect(event.keys, isNot(contains('user_id')));
      expect(event.keys, isNot(contains('device_id')));
    }
    expect(events.first['event_id'], isNot(events.last['event_id']));
  });
}
