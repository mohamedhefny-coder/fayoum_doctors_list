import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lab_model.dart';

class LabService {
  final _supabase = Supabase.instance.client;

  // تسجيل حساب معمل جديد
  Future<Map<String, dynamic>> registerLab({
    required String labName,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📝 Starting lab registration...');

      // إنشاء حساب المستخدم فقط (البيانات تُحفظ لاحقاً من AddLabScreen)
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'user_type': 'lab', 'lab_name': labName},
      );

      debugPrint('📝 Auth response: ${authResponse.user?.id}');

      if (authResponse.user == null) {
        throw Exception('فشل إنشاء الحساب');
      }

      return {
        'success': true,
        'message': 'تم إنشاء حساب المعمل بنجاح',
        'user': authResponse.user,
      };
    } on AuthException catch (e) {
      debugPrint('❌ Auth exception: ${e.message}');
      throw Exception('خطأ في التسجيل: ${e.message}');
    } catch (e) {
      debugPrint('❌ General exception: $e');
      throw Exception('حدث خطأ: $e');
    }
  }

  // تسجيل دخول المعمل
  Future<Map<String, dynamic>> loginLab({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      // التحقق من أن المستخدم هو معمل
      final userData = authResponse.user!.userMetadata;
      if (userData?['user_type'] != 'lab') {
        await _supabase.auth.signOut();
        throw Exception('هذا الحساب ليس حساب معمل');
      }

      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'user': authResponse.user,
      };
    } on AuthException catch (e) {
      throw Exception('خطأ في تسجيل الدخول: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ: $e');
    }
  }

  // الحصول على معلومات المعمل الحالي
  Future<Map<String, dynamic>?> getCurrentLab() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('labs')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المعمل: $e');
    }
  }

  // إضافة أو تحديث بيانات المعمل
  Future<void> upsertLabData({
    required String name,
    String? address,
    String? phone,
    String? whatsapp,
    String? email,
    String? workingHours,
    String? offers,
    String? contracts,
    List<String>? features,
    Map<String, List<String>>? tests,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      debugPrint('🔍 Current user: ${user?.id}');
      debugPrint('🔍 User email: ${user?.email}');

      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // البحث عن المعمل الحالي
      final existingLab = await getCurrentLab();
      debugPrint('🔍 Existing lab: $existingLab');

      final labData = {
        'user_id': user.id,
        'name': name,
        'address': address,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'working_hours': workingHours,
        'offers': offers,
        'contracts': contracts,
        'features': features,
        'tests': tests,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (existingLab != null) {
        // تحديث البيانات
        debugPrint('📝 Updating existing lab...');
        await _supabase.from('labs').update(labData).eq('user_id', user.id);
        debugPrint('✅ Lab updated successfully!');
      } else {
        // إضافة بيانات جديدة
        debugPrint('📝 Inserting new lab...');
        labData['is_published'] = true;
        await _supabase.from('labs').insert(labData);
        debugPrint('✅ Lab inserted successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error in upsertLabData: $e');
      throw Exception('خطأ في حفظ البيانات: $e');
    }
  }

  // الحصول على جميع المعامل المنشورة
  Future<List<LabModel>> getPublishedLabs() async {
    try {
      final response = await _supabase
          .from('labs')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return (response as List).map((lab) => LabModel.fromJson(lab)).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المعامل: $e');
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // التحقق من حالة تسجيل الدخول
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // الحصول على المستخدم الحالي
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
