import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RadiologyService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'radiology-images';

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

      // لا نُدرج في الجدول هنا — يتم ذلك من AddRadiologyCenterScreen بعد تسجيل الدخول

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
    String? email,
    String? workingHours,
    bool isOpen24Hours = false,
    List<String>? services,
    String? features,
    String? discounts,
    String? contracts,
    bool hasBooking = false,
    List<Map<String, String>>? doctors,
    String? coverImageUrl,
    List<String>? galleryImageUrls,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final existingCenter = await getCurrentCenter();

      // بناء البيانات مع حذف القيم الفارغة
      final Map<String, dynamic> centerData = {
        'name': name,
        'is_open_24_hours': isOpen24Hours,
        'has_booking': hasBooking,
        'is_published': true,
      };
      if (address != null) centerData['address'] = address;
      if (phone != null) centerData['phone'] = phone;
      if (whatsapp != null) centerData['whatsapp'] = whatsapp;
      if (facebook != null) centerData['facebook'] = facebook;
      if (locationUrl != null) centerData['location_url'] = locationUrl;
      if (email != null) centerData['email'] = email;
      if (workingHours != null) centerData['working_hours'] = workingHours;
      if (services != null && services.isNotEmpty) centerData['services'] = services;
      if (features != null) centerData['features'] = features;
      if (discounts != null) centerData['discounts'] = discounts;
      if (contracts != null) centerData['contracts'] = contracts;
      if (doctors != null && doctors.isNotEmpty) centerData['doctors'] = doctors;
      if (coverImageUrl != null) centerData['cover_image_url'] = coverImageUrl;
      if (galleryImageUrls != null && galleryImageUrls.isNotEmpty) {
        centerData['gallery_image_urls'] = galleryImageUrls;
      }

      if (existingCenter != null) {
        await _supabase
            .from('radiology_centers')
            .update(centerData)
            .eq('user_id', user.id);
        debugPrint('✅ Radiology center updated!');
      } else {
        centerData['user_id'] = user.id;
        await _supabase.from('radiology_centers').insert(centerData);
        debugPrint('✅ Radiology center inserted!');
      }
    } on PostgrestException catch (e) {
      debugPrint('❌ Postgrest error: ${e.code} - ${e.message}');
      throw Exception('خطأ قاعدة البيانات: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error in upsertCenterData: $e');
      rethrow;
    }
  }

  // رفع صورة إلى Supabase Storage وإرجاع الرابط العام
  Future<String?> uploadImage(XFile file, String folder) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';

      String contentType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      final bytes = await file.readAsBytes();
      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );

      return _supabase.storage.from(_bucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  // الحصول على جميع مراكز الأشعة المنشورة
  Future<List<Map<String, dynamic>>> getPublishedCenters() async {
    try {
      final response = await _supabase
          .from('radiology_centers')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching published centers: $e');
      throw Exception('خطأ في جلب مراكز الأشعة: $e');
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool isLoggedIn() => _supabase.auth.currentUser != null;
}
