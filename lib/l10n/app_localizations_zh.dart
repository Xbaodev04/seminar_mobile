// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Street Food Go';

  @override
  String get menuTitle => 'Street Food Go — 菜单';

  @override
  String get mapTitle => '地图';

  @override
  String get poiListTitle => '地点列表';

  @override
  String get settingsTitle => '设置';

  @override
  String get statsTitle => '个人统计';

  @override
  String get narrationStatusTitle => '播报状态';

  @override
  String get recentLabel => '附近';

  @override
  String get versionLabel => '版本';

  @override
  String get playNow => '立即播放';

  @override
  String get backToMap => '返回地图';

  @override
  String get locationInfo => '位置信息：';

  @override
  String get noNarration => '当前没有正在播放的播报。';

  @override
  String get stop => '停止';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get autoPlayTitle => '到达地点时自动播放';

  @override
  String get allowNotificationsTitle => '允许通知';

  @override
  String get splashSubtitle => '进入景点区域时播放音频';

  @override
  String get permissionEnableMsg => '请启用定位服务以使用地图功能。';

  @override
  String get permissionDeniedMsg => '定位权限被拒绝。';

  @override
  String get permissionDeniedForeverMsg => '定位权限已被永久拒绝。请打开设置以授予权限。';

  @override
  String locationErrorPrefix(Object error) {
    return '获取位置错误：$error';
  }

  @override
  String get noUserPositionMsg => '当前没有可用位置。点击请求定位权限。';

  @override
  String get suggestionsLabel => '建议：';

  @override
  String get suggestion_keep_gps => '- 保持 GPS 打开以接收自动播报';

  @override
  String visitedCountLabel(Object count) {
    return '已访问地点：$count';
  }

  @override
  String totalListenLabel(Object minutes) {
    return '总收听时间：$minutes 分钟';
  }

  @override
  String get languageLabel => '语言';

  @override
  String get language_system => '系统默认';

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
  String get loginButton => '登录';

  @override
  String get createAccount => '创建账户';

  @override
  String get createAccountNew => '创建新账户';

  @override
  String get fullNameLabel => '姓名';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get passwordLabel => '密码';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get confirmPasswordRequiredMsg => '请确认密码';

  @override
  String get passwordMismatchMsg => '密码不匹配';

  @override
  String get enterNameMsg => '请输入姓名';

  @override
  String get enterEmailMsg => '请输入电子邮件';

  @override
  String get enterPasswordMsg => '请输入密码';

  @override
  String get passwordMinLengthMsg => '密码至少需要6个字符';

  @override
  String get loginSuccessMsg => '登录成功';

  @override
  String get registerSuccessMsg => '账户创建成功';

  @override
  String get loginGoogleSuccessMsg => '使用 Google 登录成功';

  @override
  String get loginDemoSuccessMsg => '演示登录成功';

  @override
  String get loginWithGoogle => '使用 Google 登录';

  @override
  String get quickLoginDemo => '快速登录（演示）';

  @override
  String get logoutLabel => '登出';

  @override
  String get loggedOutMsg => '已登出';

  @override
  String get backToLogin => '返回登录';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get buyPackageTitle => '购买套餐';

  @override
  String get noActivePackageMsg => '您尚未订购套餐。请购买套餐以继续。';

  @override
  String get buyNowToast => '购买功能将会实现';

  @override
  String get buyNowButton => '立即购买';

  @override
  String get skipPurchase => '跳过（试用）';

  @override
  String get forgotPasswordDesc => '输入您的电子邮件以接收重置代码。';

  @override
  String get resetSentMsg => '密码重置邮件已发送';

  @override
  String get sendResetButton => '发送';

  @override
  String get resetSuccessMsg => '密码重置成功';

  @override
  String get resendOtpText => '重新发送';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get resetPasswordDesc => '输入发送到您邮箱的代码并选择新密码';

  @override
  String get codeSentTo => '代码已发送至：';

  @override
  String get otpLabel => '验证码';

  @override
  String get newPasswordLabel => '新密码';

  @override
  String get resetButton => '重置';

  @override
  String get emailVerificationTitle => '邮箱验证';

  @override
  String get emailVerificationDesc => '输入发送到您邮箱的验证码';

  @override
  String get verifyButtonText => '验证';

  @override
  String get backToRegister => '返回注册';

  @override
  String get bottom_home => '首页';

  @override
  String get bottom_notifications => '通知';

  @override
  String get bottom_profile => '个人';

  @override
  String get bottom_calendar => '日历';

  @override
  String get bottom_settings => '设置';

  @override
  String get searchPoiHint => '搜索摊位、地点...';

  @override
  String get ownerLabel => '老板：';

  @override
  String get descriptionTitle => '描述';

  @override
  String get contactTitle => '联系方式';

  @override
  String get phoneLabel => '电话：';

  @override
  String get websiteLabel => '网站：';

  @override
  String get infoTitle => '信息';

  @override
  String get openingHoursLabel => '营业时间：';

  @override
  String get priceRangeLabel => '价格范围：';

  @override
  String get searchHintText => '搜索摊位...';

  @override
  String get errorPrefix => '错误：';

  @override
  String get retryButton => '重试';

  @override
  String get noStallsMessage => '没有摊位';

  @override
  String get noSearchResultsMessage => '没有找到匹配的摊位';

  @override
  String get profilePageTitle => '个人资料';

  @override
  String get userLabel => '用户';

  @override
  String get editProfileLabel => '编辑资料';

  @override
  String get changePasswordLabel => '更改密码';

  @override
  String get updateProfileSuccess => '资料已更新';

  @override
  String get invalidEmailMsg => '请输入有效的电子邮件';

  @override
  String get avatarUrlLabel => '头像 URL';

  @override
  String get saveButtonLabel => '保存';

  @override
  String get loginDeviceSuccessMsg => '设备登录成功';

  @override
  String get loginWithDevice => '使用设备登录';

  @override
  String loadPoiError(Object error) {
    return '加载 POI 失败: $error';
  }

  @override
  String audioQueue(Object queueInfo) {
    return '音频队列: $queueInfo';
  }

  @override
  String alreadyListenedRecently(Object count) {
    return '您最近已经听了 $count 个摊位，请在 2 分钟后重试。';
  }

  @override
  String get pointNotInPoiZone => '选定点不在任何 POI 区域';

  @override
  String get audioQueueFinished => '音频队列播放完成';

  @override
  String nowPlaying(Object poiName) {
    return '正在播放: $poiName';
  }

  @override
  String get pleaseLoginFirst => '请先登录';

  @override
  String get scanQrCode => '扫描二维码';

  @override
  String get stallNotFound => '未找到摊位';

  @override
  String error(Object error) {
    return '错误: $error';
  }

  @override
  String get enableLocationTitle => '启用定位服务';

  @override
  String get enableLocationDesc => '请启用定位以查看附近摊位';

  @override
  String get enableLocationButton => '启用定位';

  @override
  String get enableLocationToSeeStalls => '启用定位以查看摊位';

  @override
  String get noStallsFound => '未找到附近摊位';

  @override
  String get cancelButton => '取消';

  @override
  String get exitButton => '退出';

  @override
  String get exitAppTitle => '退出应用';

  @override
  String get exitAppConfirm => '您确定要退出吗？';

  @override
  String get historyTitle => '收听历史';

  @override
  String get noHistoryMessage => '您还没有收听历史。';

  @override
  String get listenedAtLabel => '收听时间';

  @override
  String get unknownStall => '未知摊位';

  @override
  String get loadHistoryError => '加载收听历史时出错';

  @override
  String get surveyTitle => '调查';

  @override
  String get surveyQuestion => '您的收听体验如何？';

  @override
  String get surveyRatingLabel => '评分';

  @override
  String get surveyCommentLabel => '评论';

  @override
  String get surveySubmit => '提交';

  @override
  String get surveyThankYou => '感谢您的反馈！';

  @override
  String get genericError => '发生了错误。';

  @override
  String get selectPoiTitle => '选择摊位';
}
