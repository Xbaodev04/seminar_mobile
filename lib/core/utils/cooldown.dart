class Cooldown {
  final Duration duration;
  DateTime? _lastTriggerTime;

  Cooldown({required this.duration});

  bool get isReady {
    if (_lastTriggerTime == null) return true;
    return DateTime.now().difference(_lastTriggerTime!) >= duration;
  }

  void trigger() {
    _lastTriggerTime = DateTime.now();
  }

  void reset() {
    _lastTriggerTime = null;
  }
}

