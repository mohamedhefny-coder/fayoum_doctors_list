import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GymService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getCurrentGym() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('gyms')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات الجيم: $e');
    }
  }

  Future<void> upsertGymData({
    required String name,
    String? address,
    String? phone,
    String? whatsapp,
    String? geoLocation,
    String? facebookUrl,
    List<String>? gymTypes,
    List<String>? features,
    bool? is24Hours,
    bool? hasParking,
    String? priceLevel,
    String? notes,
    String? offers,
    String? discounts,
    String? coverImageUrl,
    List<String>? galleryImageUrls,
    Map<String, dynamic>? workingHours,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final existing = await getCurrentGym();

      final data = <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (whatsapp != null) data['whatsapp'] = whatsapp;
      if (geoLocation != null) data['geo_location'] = geoLocation;
      if (facebookUrl != null) data['facebook_url'] = facebookUrl;
      if (gymTypes != null) data['gym_types'] = gymTypes;
      if (features != null) data['features'] = features;
      if (is24Hours != null) data['is_24_hours'] = is24Hours;
      if (hasParking != null) data['has_parking'] = hasParking;
      if (priceLevel != null) data['price_level'] = priceLevel;
      if (notes != null) data['notes'] = notes;
      if (offers != null) data['offers'] = offers;
      if (discounts != null) data['discounts'] = discounts;
      if (coverImageUrl != null) data['cover_image_url'] = coverImageUrl;
      if (galleryImageUrls != null && galleryImageUrls.isNotEmpty) {
        data['gallery_image_urls'] = galleryImageUrls;
      }
      if (workingHours != null) {
        // PostgREST accepts JSON objects for jsonb columns.
        data['working_hours'] = jsonDecode(jsonEncode(workingHours));
      }

      if (existing != null) {
        await _supabase.from('gyms').update(data).eq('user_id', user.id);
      } else {
        data['user_id'] = user.id;
        data['is_published'] = true;
        data['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('gyms').insert(data);
      }
    } on PostgrestException catch (e) {
      throw Exception('خطأ قاعدة البيانات: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPublishedGyms() async {
    try {
      final response = await _supabase
          .from('gyms')
          .select(
            'id,name,address,phone,features,gym_types,is_24_hours,working_hours,cover_image_url,created_at',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطأ في جلب الصالات الرياضية: $e');
    }
  }

  String formatWorkingHoursShort(Map<String, dynamic>? workingHours) {
    if (workingHours == null) return 'غير متوفر';

    // Prefer showing that there is a weekly schedule.
    return 'جدول أسبوعي';
  }

  void debugLog(dynamic message) {
    if (kDebugMode) debugPrint('$message');
  }
}
