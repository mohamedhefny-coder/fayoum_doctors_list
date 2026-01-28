// ignore_for_file: avoid_print, use_key_in_widget_constructors
// ============================================
// أمثلة الاستخدام - Usage Examples
// ============================================

import 'package:fayoum_doctors_list/services/auth_service.dart';
import 'package:fayoum_doctors_list/services/doctor_database_service.dart';
import 'package:flutter/material.dart';
import 'package:fayoum_doctors_list/models/doctor_model.dart';
import 'dart:io';

// ============================================
// 1. المصادقة والتسجيل
// ============================================

// تسجيل دخول

Future<void> exampleLogin() async {
  final authService = AuthService();

  try {
    final response = await authService.signInDoctor(
      email: 'doctor@example.com',
      password: 'SecurePassword123',
    );

    print('✅ تم تسجيل الدخول بنجاح');
    print('معرف المستخدم: ${response.user?.id}');
    print('البريد الإلكتروني: ${response.user?.email}');
  } catch (e) {
    print('❌ خطأ في تسجيل الدخول: $e');
  }
}

// تسجيل حساب جديد
Future<void> exampleSignup() async {
  final authService = AuthService();

  try {
    final response = await authService.signUpDoctor(
      email: 'newdoctor@example.com',
      password: 'SecurePassword123',
      fullName: 'د. أحمد محمد',
      specialization: 'طب عام',
      phone: '+201234567890',
      licenseNumber: 'LIC123456',
    );

    print('✅ تم إنشاء الحساب بنجاح');
    print('معرف الطبيب: ${response.user?.id}');
  } catch (e) {
    print('❌ خطأ في إنشاء الحساب: $e');
  }
}

// التحقق من حالة المستخدم
Future<void> exampleCheckUserStatus() async {
  final authService = AuthService();

  if (authService.isUserLoggedIn()) {
    final user = authService.getCurrentUser();
    print('✅ المستخدم مسجل دخول: ${user?.email}');
  } else {
    print('❌ المستخدم غير مسجل دخول');
  }
}

// تسجيل الخروج
Future<void> exampleLogout() async {
  final authService = AuthService();

  try {
    await authService.signOut();
    print('✅ تم تسجيل الخروج بنجاح');
  } catch (e) {
    print('❌ خطأ في تسجيل الخروج: $e');
  }
}

// ============================================
// 2. إدارة بيانات الطبيب
// ============================================

// الحصول على بيانات الطبيب الحالي
Future<void> exampleGetCurrentProfile() async {
  final dbService = DoctorDatabaseService();

  try {
    final doctor = await dbService.getCurrentDoctorProfile();

    if (doctor != null) {
      print('✅ تم جلب البيانات بنجاح');
      print('الاسم: ${doctor.fullName}');
      print('التخصص: ${doctor.specialization}');
      print('البريد الإلكتروني: ${doctor.email}');
      print('رقم الهاتف: ${doctor.phone}');
      print('التقييم: ${doctor.rating ?? "لا يوجد تقييمات"}');
    } else {
      print('❌ لم يتم العثور على الملف الشخصي');
    }
  } catch (e) {
    print('❌ خطأ في جلب البيانات: $e');
  }
}

// تحديث بيانات الطبيب
Future<void> exampleUpdateProfile() async {
  final authService = AuthService();
  final dbService = DoctorDatabaseService();

  final user = authService.getCurrentUser();
  if (user == null) {
    print('❌ يجب تسجيل الدخول أولاً');
    return;
  }

  try {
    await dbService.updateDoctorProfile(
      doctorId: user.id,
      fullName: 'د. أحمد محمد علي',
      phone: '+201234567890',
      specialization: 'طب عام',
      bio: 'طبيب عام متخصص في التشخيص والعلاج',
    );

    print('✅ تم تحديث البيانات بنجاح');
  } catch (e) {
    print('❌ خطأ في تحديث البيانات: $e');
  }
}

// ============================================
// 3. البحث والترشيح
// ============================================

// الحصول على جميع الأطباء
Future<void> exampleGetAllDoctors() async {
  final dbService = DoctorDatabaseService();

  try {
    final doctors = await dbService.getAllDoctors();

    print('✅ تم جلب ${doctors.length} طبيب');
    for (var doctor in doctors) {
      print('- ${doctor.fullName} (${doctor.specialization})');
    }
  } catch (e) {
    print('❌ خطأ في جلب البيانات: $e');
  }
}

// البحث عن أطباء حسب التخصص
Future<void> exampleGetDoctorsBySpecialization() async {
  final dbService = DoctorDatabaseService();

  try {
    final doctors = await dbService.getDoctorsBySpecialization('طب عام');

    print('✅ تم العثور على ${doctors.length} طبيب في تخصص طب عام');
    for (var doctor in doctors) {
      print('- ${doctor.fullName}');
      print('  رقم الهاتف: ${doctor.phone}');
      print('  الموقع: ${doctor.location ?? "غير محدد"}');
      print('');
    }
  } catch (e) {
    print('❌ خطأ في البحث: $e');
  }
}

// البحث عن أطباء حسب الاسم
Future<void> exampleSearchDoctorsByName() async {
  final dbService = DoctorDatabaseService();

  try {
    final doctors = await dbService.searchDoctorsByName('أحمد');

    print('✅ نتائج البحث عن "أحمد":');
    for (var doctor in doctors) {
      print('- ${doctor.fullName}');
      print('  التخصص: ${doctor.specialization}');
      print('  التقييم: ${doctor.rating ?? "لا يوجد"}');
    }
  } catch (e) {
    print('❌ خطأ في البحث: $e');
  }
}

// ============================================
// 4. في Widget
// ============================================

class DoctorListExample extends StatefulWidget {
  @override
  State<DoctorListExample> createState() => _DoctorListExampleState();
}

class _DoctorListExampleState extends State<DoctorListExample> {
  final _dbService = DoctorDatabaseService();
  late Future<List<Doctor>> _doctorsFuture;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = _dbService.getAllDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الأطباء')),
      body: FutureBuilder<List<Doctor>>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          // تحميل البيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // خطأ
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          // بيانات فارغة
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد أطباء'));
          }

          // البيانات متاحة
          final doctors = snapshot.data!;
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(doctor.fullName),
                  subtitle: Text(doctor.specialization),
                  trailing: doctor.rating != null
                      ? Text('⭐ ${doctor.rating}')
                      : null,
                  onTap: () {
                    print('تم الضغط على: ${doctor.fullName}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================
// 5. التعامل مع الأخطاء
// ============================================

Future<void> exampleErrorHandling() async {
  final authService = AuthService();

  try {
    await authService.signInDoctor(
      email: 'invalid@example.com',
      password: 'wrong',
    );
  } on SocketException catch (e) {
    print('❌ خطأ في الاتصال: ${e.message}');
    // عرض رسالة عدم الاتصال بالإنترنت
  } catch (e) {
    print('❌ خطأ غير متوقع: $e');
    // عرض رسالة خطأ عامة
  }
}

// ============================================
// 6. استخدام Provider/GetX (اختياري)
// ============================================

// مثال باستخدام GetX (إذا تم تثبيته):
/*
import 'package:get/get.dart';

class AuthController extends GetxController {
  final authService = AuthService();
  final isLoading = false.obs;
  final currentUser = Rxn<User>();

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final response = await authService.signInDoctor(
        email: email,
        password: password,
      );
      currentUser.value = response.user;
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تسجيل الدخول: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

// الاستخدام في Widget:
class LoginPage extends StatelessWidget {
  final authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => authController.isLoading.value
          ? Center(child: CircularProgressIndicator())
          : YourLoginForm()),
    );
  }
}
*/

// ============================================
// 7. الحصول على بيانات الجلسة
// ============================================

Future<void> exampleGetSession() async {
  final authService = AuthService();

  final session = authService.getCurrentSession();

  if (session != null) {
    print('✅ جلسة نشطة');
    print('رمز الوصول: ${session.accessToken.substring(0, 20)}...');
    print('تاريخ الانتهاء: ${session.expiresAt}');
  } else {
    print('❌ لا توجد جلسة نشطة');
  }
}

// ============================================
// 8. إعادة تعيين كلمة المرور
// ============================================

Future<void> exampleResetPassword() async {
  final authService = AuthService();

  try {
    await authService.resetPassword('doctor@example.com');
    print('✅ تم إرسال رسالة إعادة التعيين إلى البريد الإلكتروني');
  } catch (e) {
    print('❌ خطأ: $e');
  }
}

// ============================================
// ملاحظات وأفضل الممارسات
// ============================================

/*
✅ يجب عليك:
1. التعامل مع جميع الأخطاء
2. إظهار رسائل مفيدة للمستخدم
3. استخدام try-catch
4. التحقق من الاتصال بالإنترنت
5. حفظ البيانات المحلية

❌ لا تفعل:
1. طلب البيانات بشكل متكرر
2. إظهار رسائل خطأ فنية للمستخدم
3. حفظ كلمات المرور
4. مشاركة tokens
5. استدعاء async functions مباشرة في build
*/
