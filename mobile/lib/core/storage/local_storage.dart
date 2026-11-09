import 'package:shared_preferences/shared_preferences.dart';

///  [AR] فئة التخزين المحلي باستخدام SharedPreferences وحفظ بيانات الجلسة والتفضيلات
///  [EN] Local Storage service using SharedPreferences for local state & user preferences
class LocalStorage {
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyLastUserUid = 'last_user_uid';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyLastCategory = 'last_category_filter';
  static const String keyLastSortBy = 'last_sort_by';

  final SharedPreferences prefs;

  LocalStorage(this.prefs);

  ///  تهيئة كائن التخزين المحلي
  static Future<LocalStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  ///  فحص ما إذا كانت هذه هي المرة الأولى لتشغيل التطبيق
  bool isFirstLaunch() {
    return prefs.getBool(keyIsFirstLaunch) ?? true;
  }

  ///  تعيين إتمام تشغيل التطبيق لأول مرة
  Future<bool> setFirstLaunchComplete() {
    return prefs.setBool(keyIsFirstLaunch, false);
  }

  ///  قراءة معرف المستخدم الأخير المسجل محلياً
  String? getLastUserUid() {
    return prefs.getString(keyLastUserUid);
  }

  ///  حفظ معرف المستخدم المسجل محلياً
  Future<bool> saveLastUserUid(String uid) {
    return prefs.setString(keyLastUserUid, uid);
  }

  ///  مسح معرف المستخدم المسجل محلياً عند تسجيل الخروج
  Future<bool> clearLastUserUid() {
    return prefs.remove(keyLastUserUid);
  }

  ///  قراءة وضع الثيم المحفوظ
  String getThemeMode() {
    return prefs.getString(keyThemeMode) ?? 'system';
  }

  ///  حفظ وضع الثيم
  Future<bool> setThemeMode(String mode) {
    return prefs.setString(keyThemeMode, mode);
  }

  ///  قراءة اللغة المحفوظة
  String getLanguage() {
    return prefs.getString(keyLanguage) ?? 'ar';
  }

  ///  حفظ اللغة
  Future<bool> setLanguage(String lang) {
    return prefs.setString(keyLanguage, lang);
  }

  ///  قراءة فئة الفلترة الأخيرة المحفوظة
  String getLastCategory() {
    return prefs.getString(keyLastCategory) ?? 'الكل';
  }

  ///  حفظ فئة الفلترة الأخيرة
  Future<bool> saveLastCategory(String cat) {
    return prefs.setString(keyLastCategory, cat);
  }

  ///  قراءة خيار الفهرسة الأخير المحفوظ
  String getLastSortBy() {
    return prefs.getString(keyLastSortBy) ?? 'newest';
  }

  ///  حفظ خيار الفهرسة الأخير
  Future<bool> saveLastSortBy(String sortBy) {
    return prefs.setString(keyLastSortBy, sortBy);
  }
}
