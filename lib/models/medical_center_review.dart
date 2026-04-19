class MedicalCenterReview {
  final String id;
  final String centerId;
  final String reviewerName;
  final String? reviewerPhone;
  final double rating;
  final String? reviewText;
  final String status; // 'approved' | 'pending' | 'rejected'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const MedicalCenterReview({
    required this.id,
    required this.centerId,
    required this.reviewerName,
    this.reviewerPhone,
    required this.rating,
    this.reviewText,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectionReason,
  });

  bool get isApproved => status == 'approved';

  factory MedicalCenterReview.fromJson(Map<String, dynamic> json) {
    return MedicalCenterReview(
      id: json['id']?.toString() ?? '',
      centerId: json['center_id']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? 'مجهول',
      reviewerPhone: json['reviewer_phone']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: json['review_text']?.toString(),
      status: json['status']?.toString() ?? 'approved',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}
