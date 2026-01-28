# دليل سريع - Supabase Authentication

## الملفات المهمة التي تم إضافتها:

### 📁 خدمات (Services)
- `lib/services/auth_service.dart` - خدمة المصادقة (تسجيل دخول، تسجيل جديد، تسجيل خروج)
- `lib/services/doctor_database_service.dart` - خدمة إدارة بيانات الأطباء

### 📁 نماذج (Models)
- `lib/models/doctor_model.dart` - نموذج بيانات الطبيب

### 📁 شاشات (Screens)
- `lib/screens/doctor_login_screen.dart` - واجهة تسجيل الدخول
- `lib/screens/doctor_signup_screen.dart` - واجهة التسجيل الجديد
- `lib/screens/doctor_profile_screen.dart` - واجهة الملف الشخصي

### 📄 ملفات التوثيق
- `SUPABASE_SETUP.md` - دليل الإعداد الكامل
- `DATABASE_SCHEMA.sql` - هيكل قاعدة البيانات

---

## خطوات البدء السريعة:

### 1️⃣ احصل على بيانات Supabase
```
اذهب إلى: https://supabase.com/dashboard
انسخ: Project URL و Anon Key
```

### 2️⃣ حدّث الملف `lib/supabase_config.dart`
```dart
static const String supabaseUrl = 'YOUR_URL_HERE';
static const String supabaseAnonKey = 'YOUR_KEY_HERE';
```

### 3️⃣ قم بإنشاء جداول قاعدة البيانات
انسخ محتوى `DATABASE_SCHEMA.sql` إلى SQL Editor في Supabase

### 4️⃣ شغّل التطبيق
```bash
flutter pub get
flutter run
```

---

## أمثلة الاستخدام:

### تسجيل دخول
```dart
final authService = AuthService();
try {
  final response = await authService.signInDoctor(
    email: 'doctor@example.com',
    password: 'password123',
  );
  print('تم تسجيل الدخول: ${response.user?.email}');
} catch (e) {
  print('خطأ: $e');
}
```

### التحقق من المستخدم المسجل دخول
```dart
final authService = AuthService();
if (authService.isUserLoggedIn()) {
  final user = authService.getCurrentUser();
  print('مرحباً ${user?.email}');
}
```

### الحصول على بيانات الطبيب
```dart
final dbService = DoctorDatabaseService();
try {
  final doctor = await dbService.getCurrentDoctorProfile();
  if (doctor != null) {
    print('الطبيب: ${doctor.fullName}');
    print('التخصص: ${doctor.specialization}');
  }
} catch (e) {
  print('خطأ: $e');
}
```

### البحث عن أطباء
```dart
// البحث حسب التخصص
final doctors = await dbService.getDoctorsBySpecialization('طب عام');

// البحث حسب الاسم
final searchResults = await dbService.searchDoctorsByName('احمد');

// الحصول على جميع الأطباء
final allDoctors = await dbService.getAllDoctors();
```

---

## الملاحة (Navigation)

لإضافة التوجيه بين الصفحات، حدّث `main.dart`:

```dart
MaterialApp(
  // ... الاعدادات الأخرى
  routes: {
    '/login': (context) => const DoctorLoginScreen(),
    '/signup': (context) => const DoctorSignupScreen(),
    '/profile': (context) => const DoctorProfileScreen(),
    '/home': (context) => const HomePage(),
  },
)
```

---

## نصائح الأمان 🔒

✅ **تم تطبيقها:**
- Row Level Security (RLS) على جميع الجداول
- السياسات تمنع قراءة/تعديل بيانات الآخرين
- المفتاح الخاص (anon key) يُستخدم فقط للقراءة العامة

⚠️ **تذكر:**
- لا تشارك `supabaseAnonKey` على GitHub
- استخدم `environment variables` للبيانات الحساسة
- فعّل HTTPS فقط في الإنتاج

---

## استكشاف الأخطاء

### المشكلة: خطأ "Invalid JWT"
❌ **السبب:** البيانات المدخلة خاطئة أو منتهية الصلاحية
✅ **الحل:** تحقق من Supabase URL و Anon Key

### المشكلة: "Failed to insert"
❌ **السبب:** الجدول غير موجود أو السياسات خاطئة
✅ **الحل:** تأكد من تنفيذ SQL Schema

### المشكلة: RLS Policy Error
❌ **السبب:** المستخدم لا يملك صلاحية للعملية
✅ **الحل:** تحقق من سياسات الأمان في Supabase

---

## موارد إضافية

- 📖 [Supabase Docs](https://supabase.com/docs)
- 🎯 [Flutter SDK Guide](https://supabase.com/docs/reference/flutter)
- 🔐 [Authentication Guide](https://supabase.com/docs/guides/auth)
- 🛡️ [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

## الخطوات التالية المقترحة:

1. ✅ اختبر تسجيل الدخول والتسجيل
2. ✅ اختبر إدارة الملف الشخصي
3. 📋 أضف نظام تقييمات الأطباء
4. 📅 أضف نظام الحجوزات (Appointments)
5. 🔍 أضف نظام بحث متقدم

---

**تم الإنشاء:** ديسمبر 2025
**الإصدار:** 1.0
**الحالة:** جاهز للاستخدام ✨
