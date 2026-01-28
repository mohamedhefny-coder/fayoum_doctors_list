class Doctor {
  final String id;
  final String email;
  final String fullName;
  final String? title;
  final String specialization;
  final String phone;
  final String licenseNumber;
  final DateTime createdAt;
  final bool isPublished;
  final bool publishRequested;
  final DateTime? publishedAt;
  final String? bio;
  final String? services;
  final double? consultationFee;
  final List<String>? galleryImageUrls;
  final String? articleUrl;
  final String? introVideoUrl;
  final String? location;
  final double? rating;
  final String? profileImageUrl;
  final String? whatsappNumber;
  final String? facebookUrl;
  final String? clinicAddress;
  final String? geoLocation;
  final String? qualifications;
  final String? workingHours;
  final String? workingHoursNotes;
  final bool emergency24h;
  final String? emergencyPhone;
  final bool homeVisit;
  final bool isBookingEnabled;
  final bool isPayAtBookingEnabled;
  final bool isCancelBookingEnabledAtPayment;
  final String? paymentMethod;
  final String? paymentAccount;
  final bool deleteRequested;
  final DateTime? deleteRequestedAt;

  Doctor({
    required this.id,
    required this.email,
    required this.fullName,
    this.title,
    required this.specialization,
    required this.phone,
    required this.licenseNumber,
    required this.createdAt,
    this.isPublished = false,
    this.publishRequested = false,
    this.publishedAt,
    this.bio,
    this.services,
    this.consultationFee,
    this.galleryImageUrls,
    this.articleUrl,
    this.introVideoUrl,
    this.location,
    this.rating,
    this.profileImageUrl,
    this.whatsappNumber,
    this.facebookUrl,
    this.clinicAddress,
    this.geoLocation,
    this.qualifications,
    this.workingHours,
    this.workingHoursNotes,
    this.emergency24h = false,
    this.emergencyPhone,
    this.homeVisit = false,
    this.isBookingEnabled = true,
    this.isPayAtBookingEnabled = false,
    this.isCancelBookingEnabledAtPayment = false,
    this.paymentMethod,
    this.paymentAccount,
    this.deleteRequested = false,
    this.deleteRequestedAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    String? readOptionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      final str = value is String ? value : value.toString();
      return str.trim().isEmpty ? null : str;
    }

    List<String>? readStringList(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is List) {
        final list = value
            .map((e) => e == null ? '' : e.toString())
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return list.isEmpty ? null : list;
      }
      return null;
    }

    DateTime readDate(String key) {
      final raw = json[key];
      if (raw == null) return DateTime.now();
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? readOptionalDate(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    bool readBool(String key, {bool fallback = false}) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final s = value.toString().toLowerCase().trim();
      if (s == 'true' || s == 't' || s == '1') return true;
      if (s == 'false' || s == 'f' || s == '0') return false;
      return fallback;
    }

    return Doctor(
      id: readString('id'),
      email: readString('email'),
      fullName: readString('full_name'),
      title: readOptionalString('title'),
      specialization: readString('specialization', fallback: 'غير محدد'),
      phone: readString('phone'),
      licenseNumber: readString('license_number'),
      createdAt: readDate('created_at'),
      isPublished: readBool('is_published', fallback: false),
      publishRequested: readBool('publish_requested', fallback: false),
      publishedAt: readOptionalDate('published_at'),
      bio: readOptionalString('bio'),
      services: readOptionalString('services'),
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
      galleryImageUrls: readStringList('gallery_image_urls'),
      articleUrl: readOptionalString('article_url'),
      introVideoUrl: readOptionalString('intro_video_url'),
      location: json['location'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      profileImageUrl: json['profile_image_url'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      facebookUrl: readOptionalString('facebook_url'),
      clinicAddress: json['clinic_address'] as String?,
      geoLocation: json['geo_location'] as String?,
      qualifications: readOptionalString('qualifications'),
      workingHours: readOptionalString('working_hours'),
      workingHoursNotes: readOptionalString('working_hours_notes'),
      emergency24h: readBool('emergency_24h', fallback: false),
      emergencyPhone: readOptionalString('emergency_phone'),
      homeVisit: readBool('home_visit', fallback: false),
      isBookingEnabled: readBool('is_booking_enabled', fallback: true),
      isPayAtBookingEnabled: readBool(
        'is_pay_at_booking_enabled',
        fallback: false,
      ),
      isCancelBookingEnabledAtPayment: readBool(
        'is_cancel_booking_enabled_at_payment',
        fallback: false,
      ),
      paymentMethod: readOptionalString('payment_method'),
      paymentAccount: readOptionalString('payment_account'),
      deleteRequested: readBool('delete_requested', fallback: false),
      deleteRequestedAt: readOptionalDate('delete_requested_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'title': title,
    'specialization': specialization,
    'phone': phone,
    'license_number': licenseNumber,
    'created_at': createdAt.toIso8601String(),
    'is_published': isPublished,
    'publish_requested': publishRequested,
    'published_at': publishedAt?.toIso8601String(),
    'bio': bio,
    'services': services,
    'consultation_fee': consultationFee,
    'gallery_image_urls': galleryImageUrls,
    'article_url': articleUrl,
    'intro_video_url': introVideoUrl,
    'location': location,
    'rating': rating,
    'profile_image_url': profileImageUrl,
    'whatsapp_number': whatsappNumber,
    'facebook_url': facebookUrl,
    'clinic_address': clinicAddress,
    'geo_location': geoLocation,
    'qualifications': qualifications,
    'working_hours': workingHours,
    'working_hours_notes': workingHoursNotes,
    'emergency_24h': emergency24h,
    'emergency_phone': emergencyPhone,
    'home_visit': homeVisit,
    'is_booking_enabled': isBookingEnabled,
    'is_pay_at_booking_enabled': isPayAtBookingEnabled,
    'is_cancel_booking_enabled_at_payment': isCancelBookingEnabledAtPayment,
    'payment_method': paymentMethod,
    'payment_account': paymentAccount,
    'delete_requested': deleteRequested,
    'delete_requested_at': deleteRequestedAt?.toIso8601String(),
  };
}
