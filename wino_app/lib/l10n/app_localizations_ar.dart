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
  String get directionsToStore => 'الاتجاهات إلى المتجر';

  @override
  String get mapLabel => 'الخريطة';

  @override
  String get openInGoogleMaps => 'فتح في Google Maps';

  @override
  String get locationDisabledTitle => 'الموقع غير مفعل';

  @override
  String get locationDisabledMessage =>
      'فعّل خدمة الموقع (GPS) من الإعدادات لاستخدام الاتجاهات.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get close => 'إغلاق';

  @override
  String get locationUnavailable => 'لا يوجد موقع';

  @override
  String get unableToOpenGoogleMaps => 'تعذر فتح Google Maps';

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

  @override
  String get authRegisterHeaderTitle => 'أنشئ حسابك';

  @override
  String get authRegisterHeaderSubtitle =>
      'ثلاث خطوات سريعة لتخصيص التسوق والعروض القريبة.';

  @override
  String get authRegisterFooterPrompt => 'لديك حساب بالفعل؟';

  @override
  String get authRegisterFooterAction => 'تسجيل الدخول';

  @override
  String get authProfileSetupHeaderTitle => 'أكمل ملفك الشخصي';

  @override
  String get authProfileSetupHeaderSubtitle =>
      'أضف بعض التفاصيل لنخصص النتائج المناسبة لك.';

  @override
  String get authProfileSetupBodySubtitle =>
      'اسمك وتاريخ ميلادك واهتماماتك تساعدنا على تخصيص المنتجات والمتاجر والعروض القريبة.';

  @override
  String get authStepPersonalTitle => 'بياناتك الأساسية';

  @override
  String get authStepPersonalSubtitle =>
      'ابدأ بالمعلومات الأساسية حتى يصبح حسابك جاهزًا من البداية.';

  @override
  String get authStepAccountTitle => 'بيانات الحساب';

  @override
  String get authStepAccountSubtitle =>
      'استخدم رقم هاتف متاحًا وكلمة مرور آمنة.';

  @override
  String get authStepInterestsTitle => 'اهتمامات التسوق';

  @override
  String get authStepInterestsSubtitle =>
      'اختر حتى 6 فئات لتحسين الاقتراحات والاكتشاف القريب.';

  @override
  String get authFieldFirstName => 'الاسم الأول';

  @override
  String get authFieldFirstNameHint => 'أدخل اسمك الأول';

  @override
  String get authFieldLastName => 'اللقب';

  @override
  String get authFieldLastNameHint => 'أدخل لقبك';

  @override
  String get authFieldFullName => 'الاسم الكامل او اسم المحل';

  @override
  String get authFieldFullNameHint => 'أدخل الاسم الكامل او اسم المحل';

  @override
  String get authFieldBirthday => 'تاريخ الميلاد';

  @override
  String get authFieldBirthdayHint =>
      'استخدم اليوم والشهر والسنة كما هي في وثائقك الرسمية.';

  @override
  String get authFieldDay => 'اليوم';

  @override
  String get authFieldDayHint => 'يوم';

  @override
  String get authFieldMonth => 'الشهر';

  @override
  String get authFieldMonthHint => 'شهر';

  @override
  String get authFieldYear => 'السنة';

  @override
  String get authFieldYearHint => 'سنة';

  @override
  String get authFieldGender => 'الجنس';

  @override
  String get authGenderMale => 'ذكر';

  @override
  String get authGenderFemale => 'أنثى';

  @override
  String get authFieldPhone => 'رقم الهاتف';

  @override
  String get authFieldPhoneHint => '0XXXXXXXXX';

  @override
  String get authFieldEmail => 'البريد الإلكتروني';

  @override
  String get authFieldEmailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get authFieldPassword => 'كلمة المرور';

  @override
  String get authFieldPasswordHint => 'أدخل كلمة المرور';

  @override
  String get authFieldConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authFieldConfirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get authFieldCategories => 'الفئات المفضلة';

  @override
  String get authFieldCategoriesHint =>
      'اختر حتى 6 فئات. يمكنك تغييرها لاحقًا.';

  @override
  String get authCategoriesCta => 'اختر فئاتك المفضلة';

  @override
  String get authCategoriesRetry => 'أعد محاولة تحميل الفئات';

  @override
  String get authCategoriesLoadError =>
      'تعذر تحميل الفئات الآن. يرجى المحاولة مرة أخرى.';

  @override
  String get authActionCreateAccount => 'إنشاء الحساب';

  @override
  String get authActionPrevious => 'السابق';

  @override
  String get authRegistrationFailed =>
      'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get authProfileSaveError =>
      'تعذر حفظ ملفك الشخصي. يرجى المحاولة مرة أخرى.';

  @override
  String get authErrorRequired => 'هذا الحقل مطلوب';

  @override
  String get authErrorNameRequired => 'أدخل اسمك الكامل';

  @override
  String get authErrorBirthdayRequired => 'أدخل تاريخ ميلادك';

  @override
  String get authErrorBirthdayInvalid => 'أدخل تاريخًا صحيحًا';

  @override
  String get authErrorMustBe13 => 'يجب أن يكون عمرك 13 سنة على الأقل';

  @override
  String get authErrorPhoneRequired => 'أدخل رقم هاتفك';

  @override
  String get authErrorPhoneInvalid =>
      'استخدم الصيغة 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX';

  @override
  String get authErrorEmailRequired => 'أدخل بريدك الإلكتروني';

  @override
  String get authErrorEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get authErrorPasswordRequired => 'أدخل كلمة مرور';

  @override
  String get authErrorPasswordMin => 'استخدم 6 أحرف على الأقل';

  @override
  String get authErrorConfirmPasswordRequired => 'أكد كلمة المرور';

  @override
  String get authErrorPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authErrorCategoriesRequired => 'اختر فئة واحدة على الأقل';

  @override
  String authStepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String categoriesPickerSelectionCount(int selected, int max) {
    return '$selected من $max محددة';
  }

  @override
  String categoriesPickerMaxReached(int max) {
    return 'يمكنك اختيار حتى $max فئات فقط.';
  }

  @override
  String categoriesPickerMinRequired(int min) {
    return 'اختر $min فئات على الأقل للمتابعة.';
  }

  @override
  String categoriesPickerMaxHint(int max) {
    return 'يمكنك اختيار حتى $max فئات.';
  }

  @override
  String get categoryPickerSearchSubtitle =>
      'اختر فئات لتضييق النتائج، أو اتركها فارغة إذا كنت تريد بحثًا أوسع.';

  @override
  String get categoryPickerProductSubtitle =>
      'اختر الفئة الواحدة الأنسب لهذا المنتج.';
}
