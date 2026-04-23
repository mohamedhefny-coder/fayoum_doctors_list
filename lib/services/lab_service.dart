import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lab_model.dart';

class LabService {
  final _supabase = Supabase.instance.client;

  // إضافة تقييم لمعمل (عبر RPC) وإرجاع التقييم الجديد وعدد التقييمات
  Future<Map<String, dynamic>> rateLab({
    required String labId,
    required int ratingValue,
  }) async {
    try {
      final response = await _supabase.rpc(
        'rate_lab',
        params: {
          'lab_id': labId,
          'rating_value': ratingValue,
        },
      );

      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first as Map);
      }
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      throw Exception('استجابة غير متوقعة من دالة التقييم');
    } on PostgrestException catch (e) {
      throw Exception('خطأ في إرسال التقييم: ${e.message}');
    } catch (e) {
      throw Exception('خطأ في إرسال التقييم: $e');
    }
  }

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
    String? coverImageUrl,
    String? logoImageUrl,
    List<String>? galleryImageUrls,
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

      // بناء البيانات مع حذف القيم الفارغة
      final Map<String, dynamic> labData = {
        'name': name,
      };
      if (address != null) labData['address'] = address;
      if (phone != null) labData['phone'] = phone;
      if (whatsapp != null) labData['whatsapp'] = whatsapp;
      if (email != null) labData['email'] = email;
      if (workingHours != null) labData['working_hours'] = workingHours;
      if (offers != null) labData['offers'] = offers;
      if (contracts != null) labData['contracts'] = contracts;
      if (coverImageUrl != null) labData['cover_image_url'] = coverImageUrl;
      if (logoImageUrl != null) labData['logo_image_url'] = logoImageUrl;
      if (galleryImageUrls != null && galleryImageUrls.isNotEmpty) {
        labData['gallery_image_urls'] = galleryImageUrls;
      }
      if (features != null && features.isNotEmpty) labData['features'] = features;
      if (tests != null && tests.isNotEmpty) {
        // تحويل Map<String, List<String>> إلى Map<String, dynamic> لضمان التوافق مع JSONB
        labData['tests'] = tests.map((k, v) => MapEntry(k, v));
      }
      if (latitude != null) labData['latitude'] = latitude;
      if (longitude != null) labData['longitude'] = longitude;

      if (existingLab != null) {
        // تحديث البيانات (بدون user_id)
        debugPrint('📝 Updating existing lab...');
        await _supabase.from('labs').update(labData).eq('user_id', user.id);
        debugPrint('✅ Lab updated successfully!');
      } else {
        // إضافة بيانات جديدة
        debugPrint('📝 Inserting new lab...');
        labData['user_id'] = user.id;
        labData['is_published'] = true;
        await _supabase.from('labs').insert(labData);
        debugPrint('✅ Lab inserted successfully!');
      }
    } on PostgrestException catch (e) {
      debugPrint('❌ Postgrest error: ${e.code} - ${e.message} - ${e.details}');
      throw Exception('خطأ قاعدة البيانات: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error in upsertLabData: $e');
      rethrow;
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
