// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'وينو';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonSearch => 'بحث';

  @override
  String get commonLanguage => 'اللغة';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonStart => 'ابدأ';

  @override
  String get commonSkip => 'تخطي';

  @override
  String get commonOpenSettings => 'فتح الإعدادات';

  @override
  String get commonBackToHome => 'العودة للرئيسية';

  @override
  String get commonNotNow => 'ليس الآن';

  @override
  String commonItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا توجد عناصر',
    );
    return '$_temp0';
  }

  @override
  String get profileSettingsEdit => 'تعديل المعلومات';

  @override
  String get profileSettingsScanQr => 'مسح QR';

  @override
  String get profileSettingsSendFeedback => 'إرسال ملاحظات';

  @override
  String get profileSettingsLanguage => 'اللغة';

  @override
  String get profileSettingsLogout => 'تسجيل الخروج';

  @override
  String get profileShareTitle => 'مشاركة الملف الشخصي';

  @override
  String get profileShareShowQr => 'عرض QR للملف الشخصي';

  @override
  String get profileShareCopyLink => 'نسخ الرابط';

  @override
  String get profileShareShare => 'مشاركة';

  @override
  String get profileShareLinkCopied => 'تم نسخ رابط الملف الشخصي';

  @override
  String get productMenuFavoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get productMenuFavoriteRemove => 'إزالة من المفضلة';

  @override
  String get productMenuShare => 'مشاركة المنتج';

  @override
  String get productMenuReport => 'الإبلاغ عن المنتج';

  @override
  String get productShareQr => 'عرض QR للمنتج';

  @override
  String get productShareCopyLink => 'نسخ الرابط';

  @override
  String get productShareShare => 'مشاركة';

  @override
  String get productShareLinkCopied => 'تم نسخ رابط المنتج';

  @override
  String get feedbackTitleSend => 'إرسال ملاحظاتك';

  @override
  String get feedbackTitleMy => 'ملاحظاتي';

  @override
  String get feedbackSubmitSuccess => 'تم إرسال الملاحظات بنجاح.';

  @override
  String get feedbackSubmitError => 'تعذر إرسال الملاحظات';

  @override
  String get feedbackEmpty => 'لم يتم إرسال أي ملاحظات بعد.';

  @override
  String get locationDisabled =>
      'خدمات الموقع متوقفة. يرجى تفعيل GPS لاستخدام البحث القريب.';

  @override
  String get locationPermissionDeniedForever =>
      'تم رفض إذن الموقع بشكل دائم. يرجى السماح به من إعدادات التطبيق.';

  @override
  String get settingsOpenLocation => 'فتح إعدادات الموقع';

  @override
  String get settingsOpenApp => 'فتح إعدادات التطبيق';

  @override
  String get errorGenericTitle => 'حدث خطأ ما';

  @override
  String get networkErrorDetails =>
      'يرجى التحقق من الاتصال ثم المحاولة مرة أخرى.';

  @override
  String get serverErrorDetails => 'عذرا، حدثت مشكلة. يرجى المحاولة لاحقا.';

  @override
  String get launchEyebrow => 'أهلا بك';

  @override
  String get launchTitle => 'ابدأ بلغتك';

  @override
  String get launchSubtitle =>
      'اختر اللغة التي تريدها للتصفح والبحث وأدوات التاجر. يمكنك تغييرها لاحقا من شاشة الملف الشخصي.';

  @override
  String get launchSearchTitle => 'ابحث بذكاء';

  @override
  String get launchSearchDescription =>
      'اعثر على المنتجات والتخفيضات والباقات أسرع داخل سوق محلي واحد.';

  @override
  String get launchNearbyTitle => 'اكتشاف قريب منك';

  @override
  String get launchNearbyDescription =>
      'استخدم GPS فقط عندما تريد نتائج حسب المسافة والعروض القريبة.';

  @override
  String get launchPrivacyTitle => 'تحكم في ظهور المتجر';

  @override
  String get launchPrivacyDescription =>
      'التاجر هو من يقرر هل يظهر متجره في النتائج القريبة أم لا.';

  @override
  String get locationEducationNearbyTitle => 'استخدم GPS للنتائج القريبة';

  @override
  String get locationEducationNearbyDescription =>
      'نستخدم موقعك فقط عندما تختار البحث القريب. هذا يساعدنا على حساب المسافة إلى المتاجر والباقات من حولك.';

  @override
  String get locationEducationStoreTitle => 'حدد موقع متجرك عبر GPS';

  @override
  String get locationEducationStoreDescription =>
      'إحداثيات المتجر تساعد البحث القريب على إظهار منتجاتك وباقاتك للزبائن المناسبين.';

  @override
  String get locationEducationPrivacyNote =>
      'التحكم يبقى بيدك. يمكنك إيقاف الظهور في النتائج القريبة لاحقا من ملف متجرك.';

  @override
  String get locationEducationRadiusHint =>
      'البحث القريب يحتاج GPS مرة واحدة حتى نقيس المسافة بدقة.';

  @override
  String get locationEducationAddressHint =>
      'فلاتر المدن تعتمد على عنوانك المحفوظ، أما الفلاتر القريبة فتعتمد على GPS.';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileTooltipShare => 'مشاركة الملف الشخصي';

  @override
  String get profileTooltipAds => 'لوحة الإعلانات';

  @override
  String get profileTooltipNotifications => 'الإشعارات';

  @override
  String get profileShareQrTitle => 'QR المتجر';

  @override
  String get profileSettingsChooseImageSource => 'اختر مصدر الصورة';

  @override
  String get profileSettingsCamera => 'الكاميرا';

  @override
  String get profileSettingsGallery => 'المعرض';

  @override
  String get feedbackTypeLabel => 'نوع الملاحظة';

  @override
  String get feedbackTypeProblem => 'مشكلة';

  @override
  String get feedbackTypeSuggestion => 'اقتراح';

  @override
  String get feedbackMessageLabel => 'الرسالة';

  @override
  String get feedbackMessageHint => 'اكتب المشكلة أو اقتراحك.';

  @override
  String get feedbackAppVersionOptional => 'إصدار التطبيق (اختياري)';

  @override
  String get feedbackDeviceInfoOptional => 'معلومات الجهاز (اختياري)';

  @override
  String get feedbackAttachScreenshotOptional => 'إرفاق لقطة شاشة (اختياري)';

  @override
  String get feedbackScreenshotSelected => 'تم اختيار لقطة الشاشة';

  @override
  String get feedbackSending => 'جارٍ الإرسال...';

  @override
  String get feedbackWriteMessageRequired => 'يرجى كتابة رسالتك.';

  @override
  String get feedbackLoadHistoryFailed => 'تعذر تحميل سجل الملاحظات.';

  @override
  String feedbackAdminNotePrefix(String note) {
    return 'ملاحظة المشرف: $note';
  }

  @override
  String get feedbackStatusOpen => 'مفتوح';

  @override
  String get feedbackStatusResolved => 'تم الحل';

  @override
  String get feedbackStatusInReview => 'قيد المراجعة';

  @override
  String get feedbackStatusRejected => 'مرفوض';

  @override
  String get feedbackTypeDefault => 'ملاحظة';

  @override
  String get qrLinkOpened => 'تم فتح رابط QR.';
}
