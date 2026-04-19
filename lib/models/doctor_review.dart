class DoctorReview {
  final String id;
  final String doctorId;
  final String reviewerName;
  final String? reviewerPhone;
  final double rating;
  final String? reviewText;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const DoctorReview({
    required this.id,
    required this.doctorId,
    required this.reviewerName,
    this.reviewerPhone,
    required this.rating,
    this.reviewText,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectionReason,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory DoctorReview.fromJson(Map<String, dynamic> json) {
    return DoctorReview(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? 'مجهول',
      reviewerPhone: json['reviewer_phone']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: json['review_text']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'reviewer_name': reviewerName,
        'reviewer_phone': reviewerPhone,
        'rating': rating,
        'review_text': reviewText,
        'status': status,
      };
}
