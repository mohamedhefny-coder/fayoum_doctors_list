import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RadiologyService {
  final _supabase = Supabase.instance.client;

  // تسجيل حساب مركز أشعة جديد
  Future<Map<String, dynamic>> registerCenter({
    required String centerName,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📝 Starting radiology center registration...');

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'user_type': 'radiology', 'center_name': centerName},
      );

      if (authResponse.user == null) {
        throw Exception('فشل إنشاء الحساب');
      }

      final centerData = {
        'user_id': authResponse.user!.id,
        'name': centerName,
        'email': email,
        'is_published': false,
      };

      try {
        await _supabase.from('radiology_centers').insert(centerData);
        debugPrint('✅ Radiology center record created!');
      } catch (e) {
        debugPrint('❌ Error inserting radiology center: $e');
        await _supabase.auth.admin.deleteUser(authResponse.user!.id);
        throw Exception('فشل في إنشاء سجل المركز: $e');
      }

      return {
        'success': true,
        'message': 'تم إنشاء حساب المركز بنجاح',
        'user': authResponse.user,
      };
    } on AuthException catch (e) {
      throw Exception('خطأ في التسجيل: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ: $e');
    }
  }

  // تسجيل دخول مركز الأشعة
  Future<Map<String, dynamic>> loginCenter({
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

      final userData = authResponse.user!.userMetadata;
      if (userData?['user_type'] != 'radiology') {
        await _supabase.auth.signOut();
        throw Exception('هذا الحساب ليس حساب مركز أشعة');
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

  // الحصول على بيانات المركز الحالي
  Future<Map<String, dynamic>?> getCurrentCenter() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('radiology_centers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المركز: $e');
    }
  }

  // إضافة أو تحديث بيانات المركز
  Future<void> upsertCenterData({
    required String name,
    String? address,
    String? phone,
    String? whatsapp,
    String? facebook,
    String? locationUrl,
    String? workingHours,
    bool isOpen24Hours = false,
    List<String>? services,
    String? features,
    String? discounts,
    String? contracts,
    bool hasBooking = false,
    List<Map<String, String>>? doctors,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final existingCenter = await getCurrentCenter();

      final centerData = {
        'user_id': user.id,
        'name': name,
        'address': address,
        'phone': phone,
        'whatsapp': whatsapp,
        'facebook': facebook,
        'location_url': locationUrl,
        'working_hours': workingHours,
        'is_open_24_hours': isOpen24Hours,
        'services': services,
        'features': features,
        'discounts': discounts,
        'contracts': contracts,
        'has_booking': hasBooking,
        'doctors': doctors,
        'is_published': true,
      };

      if (existingCenter != null) {
        await _supabase
            .from('radiology_centers')
            .update(centerData)
            .eq('user_id', user.id);
        debugPrint('✅ Radiology center updated!');
      } else {
        await _supabase.from('radiology_centers').insert(centerData);
        debugPrint('✅ Radiology center inserted!');
      }
    } catch (e) {
      debugPrint('❌ Error in upsertCenterData: $e');
      throw Exception('خطأ في حفظ البيانات: $e');
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool isLoggedIn() => _supabase.auth.currentUser != null;
}
