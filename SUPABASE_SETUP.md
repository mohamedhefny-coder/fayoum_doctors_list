# دليل إعداد Supabase لتطبيق دليل أطباء الفيوم

## خطوات الإعداد

### 1. إنشاء حساب على Supabase
- اذهب إلى [supabase.com](https://supabase.com)
- سجل حساباً جديداً أو سجل الدخول
- أنشئ مشروعاً جديداً

### 2. الحصول على بيانات الاتصال
- من لوحة المشروع، اذهب إلى **Settings** → **API**
- انسخ:
  - **Project URL** (مثلاً: `https://xxxxx.supabase.co`)
  - **anon public key** (المفتاح العام)

### 3. تحديث ملف الإعدادات
في ملف `lib/supabase_config.dart`:
```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

### 4. إنشاء جداول قاعدة البيانات

#### جدول Doctors (الأطباء)
```sql
create table public.doctors (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  full_name text not null,
  specialization text not null,
  phone text not null,
  license_number text unique not null,
  bio text,
  location text,
  rating numeric,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- تعيين السياسات
alter table public.doctors enable row level security;

-- السياسة للقراءة
create policy "Public doctors are readable by all"
  on public.doctors for select
  using (true);

-- السياسة للكتابة والتحديث والحذف (للمستخدم الخاص به فقط)
create policy "Users can manage their own doctor profile"
  on public.doctors for all
  using (auth.uid() = id)
  with check (auth.uid() = id);
```

### 5. إعداد المصادقة (Authentication)
في لوحة تحكم Supabase:

1. اذهب إلى **Authentication** → **Providers**
2. فعّل **Email** (يجب أن يكون مفعّلاً افتراضياً)
3. انتقل إلى **Email Templates** وتأكد من تفعيل نماذج البريد الإلكتروني

### 6. تثبيت المكتبات
تم إضافة `supabase_flutter: ^1.10.0` إلى `pubspec.yaml`

قم بتنفيذ:
```bash
flutter pub get
```

## الملفات المضافة

### 1. **lib/services/auth_service.dart**
خدمة المصادقة التي توفر:
- تسجيل دخول الطبيب
- إنشاء حساب جديد
- تسجيل الخروج
- إعادة تعيين كلمة المرور

### 2. **lib/services/doctor_database_service.dart**
خدمة إدارة بيانات الأطباء:
- جلب بيانات الطبيب الحالي
- تحديث البيانات الشخصية
- البحث عن الأطباء
- حذف الحساب

### 3. **lib/models/doctor_model.dart**
نموذج بيانات الطبيب يتضمن:
- المعرّف
- البريد الإلكتروني
- الاسم الكامل
- التخصص
- رقم الهاتف
- رقم الترخيص
- السيرة الذاتية
- الموقع
- التقييم

### 4. **lib/screens/doctor_login_screen.dart**
واجهة تسجيل الدخول للأطباء

### 5. **lib/screens/doctor_signup_screen.dart**
واجهة إنشاء حساب جديد للأطباء

## الاستخدام في التطبيق

### تسجيل الدخول
```dart
final authService = AuthService();
final response = await authService.signInDoctor(
  email: 'doctor@example.com',
  password: 'password123',
);
```

### إنشاء حساب
```dart
await authService.signUpDoctor(
  email: 'doctor@example.com',
  password: 'password123',
  fullName: 'احمد محمد',
  specialization: 'طب عام',
  phone: '+201234567890',
  licenseNumber: 'LIC123456',
);
```

### الحصول على بيانات الطبيب الحالي
```dart
final dbService = DoctorDatabaseService();
final doctor = await dbService.getCurrentDoctorProfile();
```

### البحث عن أطباء
```dart
final doctors = await dbService.getDoctorsBySpecialization('طب عام');
final searchResults = await dbService.searchDoctorsByName('احمد');
```

## معلومات إضافية

### Row Level Security (RLS)
تم إعداد سياسات أمان على مستوى الصف:
- جميع المستخدمين يمكنهم قراءة بيانات الأطباء
- كل طبيب يمكنه تعديل بيانته الخاصة فقط

### التعامل مع الأخطاء
جميع الدوال تستخدم `try-catch` للتعامل مع الأخطاء.

### الجلسات
يتم إدارة جلسات المستخدمين تلقائياً من قبل `supabase_flutter`.

## الخطوات التالية

1. اختبر تسجيل الدخول والتسجيل
2. أضف واجهات لإدارة البيانات الشخصية
3. أنشئ واجهة لعرض قائمة الأطباء
4. أضف نظام التقييمات
5. أضف نظام المواعيد (إذا لزم الأمر)

## دعم وموارد إضافية

- [توثيق Supabase Flutter](https://supabase.com/docs/reference/flutter)
- [توثيق المصادقة](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
