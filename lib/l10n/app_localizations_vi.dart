// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Street Food Go';

  @override
  String get menuTitle => 'Street Food Go — Menu';

  @override
  String get mapTitle => 'Bản đồ';

  @override
  String get poiListTitle => 'Danh sách POI';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get statsTitle => 'Thống kê cá nhân';

  @override
  String get narrationStatusTitle => 'Trạng thái thuyết minh';

  @override
  String get recentLabel => 'Gần đây';

  @override
  String get versionLabel => 'Phiên bản';

  @override
  String get playNow => 'Phát ngay';

  @override
  String get backToMap => 'Quay lại bản đồ';

  @override
  String get locationInfo => 'Thông tin vị trí:';

  @override
  String get noNarration => 'Hiện không có thuyết minh nào đang chạy.';

  @override
  String get stop => 'Dừng';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get autoPlayTitle => 'Tự động phát khi đến điểm tham quan';

  @override
  String get allowNotificationsTitle => 'Cho phép thông báo';

  @override
  String get splashSubtitle => 'Phát audio khi đến khu vực điểm tham quan';

  @override
  String get permissionEnableMsg => 'Vui lòng bật vị trí để sử dụng tính năng bản đồ.';

  @override
  String get permissionDeniedMsg => 'Quyền vị trí bị từ chối.';

  @override
  String get permissionDeniedForeverMsg => 'Quyền vị trí bị chặn vĩnh viễn. Hãy mở cài đặt để cấp phép.';

  @override
  String locationErrorPrefix(Object error) {
    return 'Lỗi lấy vị trí: $error';
  }

  @override
  String get noUserPositionMsg => 'Chưa có vị trí hiện tại. Bấm để yêu cầu quyền vị trí.';

  @override
  String get suggestionsLabel => 'Gợi ý:';

  @override
  String get suggestion_keep_gps => '- Duy trì GPS để nhận thuyết minh tự động';

  @override
  String visitedCountLabel(Object count) {
    return 'Số POI đã ghé: $count';
  }

  @override
  String totalListenLabel(Object minutes) {
    return 'Tổng thời gian nghe: $minutes phút';
  }

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get language_system => 'Mặc định hệ thống';

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
  String get loginButton => 'Đăng nhập';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get createAccountNew => 'Tạo tài khoản mới';

  @override
  String get fullNameLabel => 'Họ tên';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get confirmPasswordLabel => 'Nhập lại mật khẩu';

  @override
  String get confirmPasswordRequiredMsg => 'Vui lòng xác nhận mật khẩu';

  @override
  String get passwordMismatchMsg => 'Mật khẩu không khớp';

  @override
  String get enterNameMsg => 'Nhập họ tên';

  @override
  String get enterEmailMsg => 'Nhập email';

  @override
  String get enterPasswordMsg => 'Nhập mật khẩu';

  @override
  String get passwordMinLengthMsg => 'Mật khẩu ít nhất 6 ký tự';

  @override
  String get loginSuccessMsg => 'Đăng nhập thành công';

  @override
  String get registerSuccessMsg => 'Tạo tài khoản thành công';

  @override
  String get loginGoogleSuccessMsg => 'Đăng nhập bằng Google thành công';

  @override
  String get loginDemoSuccessMsg => 'Đăng nhập demo thành công';

  @override
  String get loginWithGoogle => 'Đăng nhập bằng Google';

  @override
  String get quickLoginDemo => 'Đăng nhập nhanh (Demo)';

  @override
  String get logoutLabel => 'Đăng xuất';

  @override
  String get loggedOutMsg => 'Đã đăng xuất';

  @override
  String get backToLogin => 'Quay lại đăng nhập';

  @override
  String get forgotPassword => 'Quên mật khẩu';

  @override
  String get buyPackageTitle => 'Mua gói';

  @override
  String get noActivePackageMsg => 'Bạn chưa đăng ký gói. Vui lòng mua gói để tiếp tục.';

  @override
  String get buyNowToast => 'Chức năng mua sẽ được triển khai';

  @override
  String get buyNowButton => 'Mua ngay';

  @override
  String get skipPurchase => 'Bỏ qua (dùng thử)';

  @override
  String get forgotPasswordDesc => 'Nhập email để nhận mã đặt lại.';

  @override
  String get resetSentMsg => 'Mã đặt lại mật khẩu đã được gửi tới email';

  @override
  String get sendResetButton => 'Gửi';

  @override
  String get resetSuccessMsg => 'Đặt lại mật khẩu thành công';

  @override
  String get resendOtpText => 'Gửi lại mã';

  @override
  String get resetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get resetPasswordDesc => 'Nhập mã đã gửi đến email của bạn và chọn mật khẩu mới';

  @override
  String get codeSentTo => 'Mã đã gửi tới:';

  @override
  String get otpLabel => 'Mã OTP';

  @override
  String get newPasswordLabel => 'Mật khẩu mới';

  @override
  String get resetButton => 'Đặt lại';

  @override
  String get emailVerificationTitle => 'Xác thực email';

  @override
  String get emailVerificationDesc => 'Nhập mã OTP đã gửi tới email của bạn';

  @override
  String get verifyButtonText => 'Xác thực';

  @override
  String get backToRegister => 'Trở lại đăng ký';

  @override
  String get bottom_home => 'Trang chủ';

  @override
  String get bottom_notifications => 'Thông báo';

  @override
  String get bottom_profile => 'Hồ sơ';

  @override
  String get bottom_calendar => 'Lịch';

  @override
  String get bottom_settings => 'Cài đặt';

  @override
  String get searchPoiHint => 'Tìm quán, địa điểm...';

  @override
  String get ownerLabel => 'Chủ quán:';

  @override
  String get descriptionTitle => 'Mô tả';

  @override
  String get contactTitle => 'Liên hệ';

  @override
  String get phoneLabel => 'Điện thoại';

  @override
  String get websiteLabel => 'Website:';

  @override
  String get infoTitle => 'Thông tin';

  @override
  String get openingHoursLabel => 'Giờ mở cửa:';

  @override
  String get priceRangeLabel => 'Mức giá:';

  @override
  String get searchHintText => 'Tìm quán...';

  @override
  String get errorPrefix => 'Lỗi: ';

  @override
  String get retryButton => 'Thử lại';

  @override
  String get noStallsMessage => 'Không có quán nào';

  @override
  String get noSearchResultsMessage => 'Không tìm thấy quán phù hợp';

  @override
  String get profilePageTitle => 'Hồ sơ cá nhân';

  @override
  String get userLabel => 'Người dùng';

  @override
  String get editProfileLabel => 'Chỉnh sửa hồ sơ';

  @override
  String get changePasswordLabel => 'Thay đổi mật khẩu';

  @override
  String get updateProfileSuccess => 'Cập nhật hồ sơ thành công';

  @override
  String get invalidEmailMsg => 'Vui lòng nhập email hợp lệ';

  @override
  String get avatarUrlLabel => 'URL ảnh đại diện';

  @override
  String get saveButtonLabel => 'Lưu';

  @override
  String get loginDeviceSuccessMsg => 'Đăng nhập bằng thiết bị thành công';

  @override
  String get loginWithDevice => 'Đăng nhập bằng thiết bị';

  @override
  String loadPoiError(Object error) {
    return 'Tải POI thất bại: $error';
  }

  @override
  String audioQueue(Object queueInfo) {
    return 'Hàng đợi âm thanh: $queueInfo';
  }

  @override
  String alreadyListenedRecently(Object count) {
    return 'Bạn đã nghe $count quán này gần đây rồi, vui lòng thử lại sau 2 phút.';
  }

  @override
  String get pointNotInPoiZone => 'Điểm đã chọn không ở vùng POI nào';

  @override
  String get audioQueueFinished => 'Đã phát xong hàng đợi âm thanh';

  @override
  String nowPlaying(Object poiName) {
    return 'Đang phát: $poiName';
  }

  @override
  String get pleaseLoginFirst => 'Vui lòng đăng nhập trước';

  @override
  String get scanQrCode => 'Quét mã QR';

  @override
  String get stallNotFound => 'Không tìm thấy quán';

  @override
  String error(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String get enableLocationTitle => 'Bật dịch vụ vị trí';

  @override
  String get enableLocationDesc => 'Vui lòng bật vị trí để xem quán gần đây';

  @override
  String get enableLocationButton => 'Bật vị trí';

  @override
  String get enableLocationToSeeStalls => 'Bật vị trí để xem quán';

  @override
  String get noStallsFound => 'Không tìm thấy quán gần đây';

  @override
  String get cancelButton => 'Hủy';

  @override
  String get exitButton => 'Thoát';

  @override
  String get exitAppTitle => 'Thoát ứng dụng';

  @override
  String get exitAppConfirm => 'Bạn có chắc chắn muốn thoát?';

  @override
  String get historyTitle => 'Lịch sử nghe';

  @override
  String get noHistoryMessage => 'Bạn chưa có lịch sử nghe.';

  @override
  String get listenedAtLabel => 'Nghe lúc';

  @override
  String get unknownStall => 'Quán không xác định';

  @override
  String get loadHistoryError => 'Lỗi khi tải lịch sử nghe';

  @override
  String get surveyTitle => 'Khảo sát';

  @override
  String get surveyQuestion => 'Trải nghiệm nghe của bạn như thế nào?';

  @override
  String get surveyRatingLabel => 'Đánh giá';

  @override
  String get surveyCommentLabel => 'Bình luận';

  @override
  String get surveySubmit => 'Gửi';

  @override
  String get surveyThankYou => 'Cảm ơn bạn đã góp ý!';

  @override
  String get genericError => 'Đã có lỗi xảy ra.';

  @override
  String get selectPoiTitle => 'Chọn quán';
}
