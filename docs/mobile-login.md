# Mobile login diagnostics

Google and device login use the same Backend base URL. A physical phone on
mobile data cannot reach a development PC's private Wi-Fi IP.

## Android over USB

```powershell
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=SEMINAR_API_BASE=http://127.0.0.1:8000/api/v1
```

VS Code includes a `Flutter Android USB (adb reverse 8000)` configuration.
For an emulator use `http://10.0.2.2:8000/api/v1`. For Wi-Fi use the PC's LAN IP,
keep both devices on that LAN, and bind Uvicorn to `0.0.0.0`.

## Google OAuth

The existing Web OAuth client is used by default; override it with
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>`. The Backend's
`GOOGLE_CLIENT_ID` must allow that same Web client ID. Do not use an Android
OAuth client ID as `serverClientId`.

The Google Cloud project must also contain an Android OAuth client with package
`com.example.seminar_mobile` and the SHA-1 of the certificate signing the actual
APK. Register each development machine's signing certificate and the release
certificate when applicable. Some Android OAuth misconfigurations appear as
a canceled login; they cannot always be distinguished from cancellation by the SDK.

Current development debug certificate SHA-1:
`1A:B5:5E:1B:EC:B4:A0:4D:4D:8F:23:E5:2C:84:9F:84:9A:1B:31:4F`.
The fingerprint is public configuration; its registration in Google Cloud must
be checked by the owner of that project.

Google account selection/consent must be performed by the user on their phone.

## Device and session behavior

Guest identity is now random per installation and stored in preferences. Legacy
Android build IDs are replaced because they can be shared across phones; this
may start a new guest profile once. Clearing app data creates a new identity.
The Backend's partial email index allows multiple guests without email while
still enforcing uniqueness for real email addresses. The startup migration
creates the replacement before removing the old `email_unique` index.

Login is committed only after `/mobile/auth/me` returns a valid profile. The
client unwraps the Backend's `data` envelope. Refresh requests use the refresh
signing key on the server and retry with the NEW access token on the client.
Tokens and full login responses are not printed by the login API client.
