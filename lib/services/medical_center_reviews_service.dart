import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_center_review.dart';

class MedicalCenterReviewsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MedicalCenterReview>> getApprovedReviews({
    required String centerId,
  }) async {
    try {
      final rows = await _client
          .from('medical_center_reviews')
          .select()
          .eq('center_id', centerId)
          .eq('status', 'approved')
          .order('created_at', ascending: false) as List<dynamic>;

      return rows
          .whereType<Map<String, dynamic>>()
          .map(MedicalCenterReview.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitMedicalCenterReview({
    required String centerId,
    required String reviewerName,
    String? reviewerPhone,
    required double rating,
    String? reviewText,
  }) async {
    try {
      final response = await _client.rpc(
        'submit_medical_center_review',
        params: {
          'center_id': centerId,
          'reviewer_name': reviewerName.trim(),
          'reviewer_phone': reviewerPhone?.trim(),
          'rating_value': rating,
          'review_text': reviewText?.trim(),
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
}
