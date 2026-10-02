// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Street Food Go';

  @override
  String get menuTitle => 'Street Food Go — メニュー';

  @override
  String get mapTitle => 'マップ';

  @override
  String get poiListTitle => 'POIリスト';

  @override
  String get settingsTitle => '設定';

  @override
  String get statsTitle => '個人統計';

  @override
  String get narrationStatusTitle => 'ナレーション状態';

  @override
  String get recentLabel => '最近';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get playNow => '今すぐ再生';

  @override
  String get backToMap => 'マップに戻る';

  @override
  String get locationInfo => '位置情報:';

  @override
  String get noNarration => 'ナレーションは実行されていません。';

  @override
  String get stop => '停止';

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get autoPlayTitle => 'POIに到着時に自動再生';

  @override
  String get allowNotificationsTitle => '通知を許可';

  @override
  String get splashSubtitle => 'POIエリアに入ると音声が再生されます';

  @override
  String get permissionEnableMsg => 'マップを使用するには位置情報サービスを有効にしてください。';

  @override
  String get permissionDeniedMsg => '位置情報の許可が拒否されました。';

  @override
  String get permissionDeniedForeverMsg => '位置情報の許可が永続的に拒否されています。設定を開いて許可を付与してください。';

  @override
  String locationErrorPrefix(Object error) {
    return '位置取得エラー: $error';
  }

  @override
  String get noUserPositionMsg => '現在の位置が利用できません。タップして許可をリクエストしてください。';

  @override
  String get suggestionsLabel => '提案:';

  @override
  String get suggestion_keep_gps => '- GPSをオンに保つと自動ナレーションが受信されます';

  @override
  String visitedCountLabel(Object count) {
    return '訪問したPOI: $count';
  }

  @override
  String totalListenLabel(Object minutes) {
    return '総聴取時間: $minutes分';
  }

  @override
  String get languageLabel => '言語';

  @override
  String get language_system => 'システムデフォルト';

  @override
  String get language_en_label => 'English';

  @override
  String get language_vi_label => 'Tiếng Việt';

  @override
  String get language_zh_label => '中文';

  @override
  String get language_ko_label => '한국어';

  @override
  String get language_ja_label => '日本語';

  @override
  String get loginButton => 'ログイン';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get createAccountNew => '新しいアカウントを作成';

  @override
  String get fullNameLabel => 'フルネーム';

  @override
  String get emailLabel => 'メール';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get confirmPasswordLabel => 'パスワード確認';

  @override
  String get confirmPasswordRequiredMsg => 'パスワードを確認してください';

  @override
  String get passwordMismatchMsg => 'パスワードが一致しません';

  @override
  String get enterNameMsg => 'フルネームを入力してください';

  @override
  String get enterEmailMsg => 'メールを入力してください';

  @override
  String get enterPasswordMsg => 'パスワードを入力してください';

  @override
  String get passwordMinLengthMsg => 'パスワードは最低6文字である必要があります';

  @override
  String get loginSuccessMsg => 'ログインに成功しました';

  @override
  String get registerSuccessMsg => 'アカウントが正常に作成されました';

  @override
  String get loginGoogleSuccessMsg => 'Googleでのサインインに成功しました';

  @override
  String get loginDemoSuccessMsg => 'デモログインに成功しました';

  @override
  String get loginWithGoogle => 'Googleでサインイン';

  @override
  String get quickLoginDemo => 'クイックログイン (デモ)';

  @override
  String get logoutLabel => 'サインアウト';

  @override
  String get loggedOutMsg => 'サインアウトしました';

  @override
  String get backToLogin => 'ログインに戻る';

  @override
  String get forgotPassword => 'パスワードをお忘れですか';

  @override
  String get buyPackageTitle => 'パッケージを購入';

  @override
  String get noActivePackageMsg => 'アクティブなパッケージがありません。続行するにはパッケージを購入してください。';

  @override
  String get buyNowToast => '購入フローはまもなく実装されます';

  @override
  String get buyNowButton => '今すぐ購入';

  @override
  String get skipPurchase => 'スキップ (トライアル)';

  @override
  String get forgotPasswordDesc => 'パスワードリセットコードを受け取るにはメールを入力してください。';

  @override
  String get resetSentMsg => 'パスワードリセットメールが送信されました';

  @override
  String get sendResetButton => '送信';

  @override
  String get resetSuccessMsg => 'パスワードリセットに成功しました';

  @override
  String get resendOtpText => '再送信';

  @override
  String get resetPasswordTitle => 'パスワードをリセット';

  @override
  String get resetPasswordDesc => 'メールで受け取ったコードを入力し、新しいパスワードを選択してください';

  @override
  String get codeSentTo => 'コード送信先:';

  @override
  String get otpLabel => 'OTP';

  @override
  String get newPasswordLabel => '新しいパスワード';

  @override
  String get resetButton => 'リセット';

  @override
  String get emailVerificationTitle => 'メール認証';

  @override
  String get emailVerificationDesc => 'メールで受け取ったコードを入力してください';

  @override
  String get verifyButtonText => '認証';

  @override
  String get backToRegister => '登録に戻る';

  @override
  String get bottom_home => 'ホーム';

  @override
  String get bottom_notifications => '通知';

  @override
  String get bottom_profile => 'プロフィール';

  @override
  String get bottom_calendar => 'カレンダー';

  @override
  String get bottom_settings => '設定';

  @override
  String get searchPoiHint => '屋台や場所を検索...';

  @override
  String get ownerLabel => 'オーナー：';

  @override
  String get descriptionTitle => '説明';

  @override
  String get contactTitle => 'お問い合わせ';

  @override
  String get phoneLabel => '電話';

  @override
  String get websiteLabel => 'ウェブサイト：';

  @override
  String get infoTitle => '情報';

  @override
  String get openingHoursLabel => '営業時間：';

  @override
  String get priceRangeLabel => '価格帯：';

  @override
  String get searchHintText => '屋台を検索...';

  @override
  String get errorPrefix => 'エラー：';

  @override
  String get retryButton => '再試行';

  @override
  String get noStallsMessage => '屋台がありません';

  @override
  String get noSearchResultsMessage => '一致する屋台がありません';

  @override
  String get profilePageTitle => 'プロフィール';

  @override
  String get userLabel => 'ユーザー';

  @override
  String get editProfileLabel => 'プロフィール編集';

  @override
  String get changePasswordLabel => 'パスワード変更';

  @override
  String get updateProfileSuccess => 'プロフィールを更新しました';

  @override
  String get invalidEmailMsg => '有効なメールアドレスを入力してください';

  @override
  String get avatarUrlLabel => 'アバターURL';

  @override
  String get saveButtonLabel => '保存';

  @override
  String get loginDeviceSuccessMsg => 'デバイスでのログインに成功しました';

  @override
  String get loginWithDevice => 'デバイスでログイン';

  @override
  String loadPoiError(Object error) {
    return 'POIの読み込みに失敗しました: $error';
  }

  @override
  String audioQueue(Object queueInfo) {
    return 'オーディオキュー: $queueInfo';
  }

  @override
  String alreadyListenedRecently(Object count) {
    return '最近すでに $count 軒の屋台を聴きました。2分後に再試行してください。';
  }

  @override
  String get pointNotInPoiZone => '選択した地点はPOIゾーン内ではありません';

  @override
  String get audioQueueFinished => 'オーディオキュー再生完了';

  @override
  String nowPlaying(Object poiName) {
    return '再生中: $poiName';
  }

  @override
  String get pleaseLoginFirst => '先にログインしてください';

  @override
  String get scanQrCode => 'QRコードをスキャン';

  @override
  String get stallNotFound => '屋台が見つかりません';

  @override
  String error(Object error) {
    return 'エラー: $error';
  }

  @override
  String get enableLocationTitle => '位置情報サービスを有効にしてください';

  @override
  String get enableLocationDesc => '近くの屋台を見るには位置情報を有効にしてください';

  @override
  String get enableLocationButton => '位置情報を有効にする';

  @override
  String get enableLocationToSeeStalls => '屋台を見るには位置情報を有効にしてください';

  @override
  String get noStallsFound => '近くに屋台が見つかりません';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get exitButton => '終了';

  @override
  String get exitAppTitle => 'アプリを終了';

  @override
  String get exitAppConfirm => '本当に終了してもよろしいですか？';

  @override
  String get historyTitle => '聴取履歴';

  @override
  String get noHistoryMessage => '聴取履歴がありません。';

  @override
  String get listenedAtLabel => '聴取時間';

  @override
  String get unknownStall => '不明な屋台';

  @override
  String get loadHistoryError => '聴取履歴の読み込みエラー';

  @override
  String get surveyTitle => 'アンケート';

  @override
  String get surveyQuestion => '聴取体験はいかがでしたか？';

  @override
  String get surveyRatingLabel => '評価';

  @override
  String get surveyCommentLabel => 'コメント';

  @override
  String get surveySubmit => '送信';

  @override
  String get surveyThankYou => 'フィードバックありがとうございます！';

  @override
  String get genericError => 'エラーが発生しました.';

  @override
  String get selectPoiTitle => '屋台を選択';
}
