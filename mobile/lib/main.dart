// استدعاء مكتبات فلاتر وإدارة الحالة (Bloc)
import 'package:flutter/material.dart'; // المكتبة الأساسية لعناصر الواجهة وتصميم الـ Material
import 'package:flutter_bloc/flutter_bloc.dart'; // مكتبة إدارة الحالة (State Management)

// استدعاء البنية التحتية المركزية (Core Layer)
import 'core/network/dio_client.dart'; // عميل HTTP المركزي لإرسال الطلبات لسيرفر Laravel
import 'core/services/firebase_service.dart'; // خدمة تهيئة خدمات Firebase وقراءة المفاتيح
import 'core/storage/local_storage.dart'; // غلاف SharedPreferences للتخزين المحلي والتفضيلات

// استدعاء طبقات ميزة المصادقة (Auth Feature) بحسب المعمارية النظيفة Clean Architecture
import 'features/auth/data/datasources/auth_remote_data_source.dart'; // طبقة البيانات: الاتصال بـ FirebaseAuth
import 'features/auth/data/repositories/auth_repository_impl.dart'; // طبقة البيانات: المنفذ الفعلي لعقد الـ Domain
import 'features/auth/presentation/cubits/auth_cubit.dart'; // طبقة العرض: الكيوبت المسؤول عن إدارة حالات الدخول
import 'features/auth/presentation/screens/auth_screen.dart'; // طبقة العرض: شاشة تسجيل الدخول وإنشاء الحساب
import 'features/tasks_home/presentation/screens/home_screen.dart'; // طبقة العرض: الشاشة الرئيسية للمهام

// ============================================================================
// نقطة الدخول والانطلاق الأولى للتطبيق (Main Entry Point)
// ============================================================================
Future<void> main() async {
  // 1. ضمان جاهزية محرك فلاتر والتواصل مع النظام الأصلي (Android/iOS) قبل أي عملية async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة خدمات Firebase وقراءة ملف google-services.json بأمان
  await FirebaseService.initialize();

  // 3. فتح وتجهيز التخزين المحلي (SharedPreferences) لقراءة التفضيلات
  final localStorage = await LocalStorage.init();

  // 4. فحص هل هذه أول مرة يفتح فيها المستخدم التطبيق؛ إن كانت كذلك نحفظ أنها تمت
  if (localStorage.isFirstLaunch()) {
    await localStorage.setFirstLaunchComplete();
  }

  // 5. تطبيق الـ Dependency Injection: بناء AuthCubit وتمرير طبقات المعمارية النظيفة إليه
  // واستدعاء دالة checkSession() فوراً عبر معامل الكاسكيد (..) للتحقق من وجود مستخدم سابق
  final authCubit = AuthCubit(
    AuthRepositoryImpl(AuthRemoteDataSource()),
    localStorage: localStorage,
  )..checkSession();

  // 6. تشغيل الواجهة وتمرير الخدمات الأساسية الجاهزة إلى الودجت الجذرية HayyApp
  runApp(
    HayyApp(
      authCubit: authCubit,
      dioClient: DioClient(),
      localStorage: localStorage,
    ),
  );
}

// ============================================================================
// الودجت الجذرية الشاملة للتطبيق (Root Widget)
// ============================================================================
class HayyApp extends StatelessWidget {
  // مراجع الخدمات المحقونة (Injected Dependencies)
  final AuthCubit authCubit; // كائن إدارة المصادقة
  final DioClient dioClient; // كائن عميل الاتصال بسيرفر Laravel
  final LocalStorage? localStorage; // كائن التخزين المحلي

  const HayyApp({
    super.key,
    required this.authCubit,
    required this.dioClient,
    this.localStorage,
  });

  @override
  Widget build(BuildContext context) {
    // توفير كائن AuthCubit الجاهز مسبقاً لشجرة الودجات بالكامل دون إعادة إنشائه
    return BlocProvider.value(
      value: authCubit,
      child: MaterialApp(
        title: 'حيّ | مساعدة مجتمعية', // اسم التطبيق في مدير المهام
        debugShowCheckedModeBanner: false, // إخفاء شريط الـ Debug الأحمر المائل في الزاوية

        // --------------------------------------------------------------------
        // ضبط الهوية البصرية والمظهر العام (Centralized Theming)
        // --------------------------------------------------------------------
        theme: ThemeData(
          // لوحة الألوان المتناسقة بنظام Material 3
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00695C), // لون البذرة لاستخراج الدرجات
            primary: const Color(0xFF00695C), // اللون الأساسي للتطبيق (البترولي/الزيتي)
            secondary: const Color(0xFF004D40), // اللون الثانوي التفاعلي (درجة أغمق)
          ),
          scaffoldBackgroundColor: const Color(0xFFFAF6F0), // لون خلفية مريح للعين (بيج هادئ)
          useMaterial3: true, // تفعيل نمط التصميم الحديث Material 3
          fontFamily: 'Roboto', // الخط المعتمد لنصوص التطبيق

          // ضبط تصميم حقول الإدخال (TextFormField) مركزياً لترثه جميع الشاشات
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white, // خلفية بيضاء داخل الحقل
            // الإطار الافتراضي
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), // حواف دائرية بمقدار 16 بكسل
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            // الإطار عندما يكون الحقل غير مضغوط
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            // الإطار عند الضغط عليه للكتابة (Focused)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00695C), width: 2), // إطار بترولي عريض
            ),
          ),
        ),

        // --------------------------------------------------------------------
        // إجبار اتجاه الواجهة من اليمين لليسار لدعم اللغة العربية (RTL Direction)
        // --------------------------------------------------------------------
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl, // اتجاه الواجهة يمين-إلى-يسار
          child: child ?? const SizedBox.shrink(),
        ),

        // --------------------------------------------------------------------
        // الشاشة الأولى (Home): تتحدد ديناميكياً بحسب حالة المستخدم في AuthCubit
        // --------------------------------------------------------------------
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            // الحالة 1: فحص الجلسة أو التحميل الجاري -> عرض مؤشر انتظار دائري
            if (state is AuthChecking ||
                state is AuthInitial ||
                state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00695C)),
                ),
              );
            }

            // الحالة 2: المستخدم مسجل دخوله بنجاح وموثق -> التوجيه المباشر للشاشة الرئيسية
            if (state is AuthAuthenticated) {
              return HomeScreen(
                user: state.user, // تمرير بيانات المستخدم الحالي (AppUser)
                dioClient: dioClient,
                authCubit: authCubit,
                localStorage: localStorage,
              );
            }

            // الحالة 3: لا يوجد مستخدم أو حدث خطأ -> عرض شاشة تسجيل الدخول
            return AuthScreen(cubit: authCubit);
          },
        ),
      ),
    );
  }
}