import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HospitalService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> registerHospital({
    required String hospitalName,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🏥 Starting hospital registration...');

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'user_type': 'private_hospital', 'hospital_name': hospitalName},
      );

      if (authResponse.user == null) {
        throw Exception('فشل إنشاء الحساب');
      }

      return {
        'success': true,
        'message': 'تم إنشاء حساب المستشفى بنجاح',
        'user': authResponse.user,
      };
    } on AuthException catch (e) {
      throw Exception('خطأ في التسجيل: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ: $e');
    }
  }

  Future<Map<String, dynamic>> loginHospital({
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
      if (userData?['user_type'] != 'private_hospital') {
        await _supabase.auth.signOut();
        throw Exception('هذا الحساب ليس حساب مستشفى خاص');
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

  Future<Map<String, dynamic>?> getCurrentHospital() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('private_hospitals')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المستشفى: $e');
    }
  }

  Future<void> upsertHospitalData({
    required String name,
    String? address,
    String? phone,
    String? whatsapp,
    String? geoLocation,
    String? facebookUrl,
    List<String>? departments,
    bool? hasEmergency24,
    String? notes,
    String? coverImageUrl,
    List<String>? galleryImageUrls,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final existing = await getCurrentHospital();

      final data = <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (whatsapp != null) data['whatsapp'] = whatsapp;
      if (geoLocation != null) data['geo_location'] = geoLocation;
      if (facebookUrl != null) data['facebook_url'] = facebookUrl;
      if (departments != null) data['departments'] = departments;
      if (hasEmergency24 != null) data['has_emergency_24'] = hasEmergency24;
      if (notes != null) data['notes'] = notes;
      if (coverImageUrl != null) data['cover_image_url'] = coverImageUrl;
      if (galleryImageUrls != null && galleryImageUrls.isNotEmpty) {
        data['gallery_image_urls'] = galleryImageUrls;
      }

      if (existing != null) {
        await _supabase.from('private_hospitals').update(data).eq(
              'user_id',
              user.id,
            );
      } else {
        data['user_id'] = user.id;
        data['is_published'] = true;
        data['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('private_hospitals').insert(data);
      }
    } on PostgrestException catch (e) {
      throw Exception('خطأ قاعدة البيانات: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPublishedHospitals() async {
    try {
      final response = await _supabase
          .from('private_hospitals')
          .select(
            'id,name,address,phone,geo_location,facebook_url,departments,has_emergency_24,cover_image_url,gallery_image_urls,created_at',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطأ في جلب المستشفيات: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
