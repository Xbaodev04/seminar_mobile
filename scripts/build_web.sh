#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  flutter_sdk_dir="$PWD/.vercel/flutter-sdk"
  if [ ! -x "$flutter_sdk_dir/bin/flutter" ]; then
    git clone --depth 1 --branch "${FLUTTER_VERSION:-3.47.5}" \
      https://github.com/flutter/flutter.git "$flutter_sdk_dir"
  fi
  export PATH="$flutter_sdk_dir/bin:$PATH"
fi

flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define="SEMINAR_API_BASE=${SEMINAR_API_BASE:-/api/v1}" \
  --dart-define="SEMINAR_WS_BASE=${SEMINAR_WS_BASE:-}"
