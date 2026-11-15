# POI audio: Tier 1 and Tier 1.5

Configure the Backend origin through the existing define:

```powershell
flutter run --dart-define=SEMINAR_API_BASE=http://10.0.2.2:8000/api/v1
```

Use `localhost` for Windows/web and the development machine's LAN address for
a physical phone. Start the Backend with its MongoDB replica set first.

- Tier 1 plays `audio_url` only when content is not fallback and matches the requested language.
- Otherwise Mobile posts `{poi_id, lang}` to `/localizations/on-demand`.
- Successful JSON is a direct object, without a `data` envelope. It must contain
  `audio_status=completed`, `is_fallback=false`, the requested `lang`, translated
  text, title and an audio URL. Static audio URLs resolve against the Backend origin.
- The player updates the displayed title/text and retains the generated URL for replay.
- The client deadline is 50 seconds, slightly longer than the Backend's 45 seconds.
- `Retry-After` on 429/503 prevents repeated requests during cooldown.
- On-demand or MP3 errors fall back to device speech; use the actual source text
  language when localization failed. This flow does not call Google Translate from Mobile.
- Stop, pause, leaving a POI and changing locale invalidate pending playback.
  Requests already received by the Backend may still finish and populate its cache.
- Waiting for translation/TTS is excluded from listening history. The mini player
  displays a progress indicator while preparing; its button can pause preparation.

This change integrates Tier 1.5. The existing `/audio/tts` Tier 2 stream is not
integrated here; Backend streaming remains separate work. Device TTS is the final
fallback and requires an installed voice for the language on that device.

```powershell
flutter test --no-pub
flutter analyze --no-pub
```

Tests cover the HTTP contract, failures and cooldown, selection between Tier 1
and Tier 1.5, local speech, stop/pause and late responses. Audio/TTS are fakes in
automated orchestration tests. Also verify real MP3 playback, voice availability
and offline behavior on Android before release.
