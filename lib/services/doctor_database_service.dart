import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'dart:io';
import '../models/doctor_model.dart';
import '../models/doctor_working_hours.dart';

class DoctorDatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _doctorsBucket = 'doctors';
  static const String _galleryFolder = 'gallery';
  static const String _introVideoFolder = 'intro_videos';
  static const int _maxIntroVideoBytes = 30 * 1024 * 1024; // 30MB

  String _normalizeSpecialtyLabel(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// UI labels in the home/specialties screens are sometimes shorter than the
  /// values saved in `doctors.specialization` (e.g. "جلدية" vs "جلدية وتناسلية").
  ///
  /// Return a small alias set to maximize matching without making queries too
  /// broad.
  List<String> _specialtyAliases(String specialty) {
    final s = _normalizeSpecialtyLabel(specialty);
    final aliases = <String>{s};

    // Common short labels used in the UI.
    switch (s) {
      case 'باطنة':
        aliases.add('باطنة (أمراض باطنة)');
        break;
      case 'جلدية':
        aliases.add('جلدية وتناسلية');
        break;
      case 'عظام':
        aliases.add('جراحة عظام');
        break;
      case 'صدرية':
        aliases.add('صدرية (أمراض الصدر)');
        break;
      case 'كلى':
        aliases.add('كُلى (أمراض الكلى)');
        aliases.add('كلى (أمراض الكلى)');
        break;
      default:
        break;
    }

    return aliases.toList(growable: false);
  }

  static const String appointmentStatusPending = 'pending';
  static const String appointmentStatusAccepted = 'accepted';
  static const String appointmentStatusRejected = 'rejected';

  bool _looksLikeMissingColumn(String message, String columnName) {
    final m = message.toLowerCase();
    final c = columnName.toLowerCase();
    return (m.contains('column') &&
            m.contains(c) &&
            m.contains('does not exist')) ||
        (m.contains('unknown') && m.contains('column') && m.contains(c));
  }

  String _normalizePhoneToE164(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return trimmed;
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      return '+20${digits.substring(1)}';
    }
    if (digits.startsWith('20') && digits.length == 12) {
      return '+$digits';
    }
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }
    return '+$digits';
  }

  // الحصول على بيانات الطبيب الحالي
  Future<Doctor?> getCurrentDoctorProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('doctors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return Doctor.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Ensure a doctor profile row exists for the current authenticated user.
  ///
  /// Why: The app assumes `doctors.id == auth.uid()` for profile CRUD (RLS).
  /// If the row is missing (or was created with a random UUID), profile reads
  /// will fail (often as PGRST116) and the screen looks blank.
  Future<Doctor> ensureCurrentDoctorProfile({
    String defaultSpecialization = 'غير محدد',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً.');
    }

    final existingById = await _client
        .from('doctors')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existingById != null) {
      return Doctor.fromJson(existingById);
    }

    // If a row exists for the same email but with a different id, we can't
    // auto-fix safely (unique constraints + foreign keys). Provide guidance.
    final email = user.email;
    if (email != null && email.trim().isNotEmpty) {
      final existingByEmail = await _client
          .from('doctors')
          .select('id,email,full_name,specialization')
          .eq('email', email.trim())
          .maybeSingle();

      if (existingByEmail != null) {
        final existingId = (existingByEmail['id'] ?? '').toString();
        throw Exception(
          'لا يمكن فتح الملف الشخصي لأن سجل الطبيب في جدول doctors لا يطابق حساب الدخول.\n'
          'User ID (auth.uid): ${user.id}\n'
          'Doctor row id: $existingId\n'
          'الحل: اجعل doctors.id يساوي auth user id (أو احذف السجل القديم وأعد إدخاله بالـ id الصحيح).',
        );
      }
    }

    // Create a minimal row owned by the user.
    try {
      await _client.from('doctors').insert({
        'id': user.id,
        'email': email,
        'specialization': defaultSpecialization,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      final msg = e.toString();

      // If the row already exists (duplicate PK) but we couldn't SELECT it,
      // this strongly suggests missing/incorrect SELECT policy under RLS.
      final looksLikePkConflict =
          msg.contains('23505') &&
          (msg.contains('doctors_pkey') ||
              msg.toLowerCase().contains('duplicate key'));

      if (!looksLikePkConflict) {
        rethrow;
      }
    }

    final after = await _client
        .from('doctors')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (after == null) {
      throw Exception(
        'تم العثور على تعارض (السجل موجود بالفعل) لكن التطبيق لا يستطيع قراءته.\n'
        'هذا غالباً بسبب سياسات RLS/SELECT على جدول doctors.\n'
        'الحل: أضف سياسة SELECT للطبيب (أو للعامة) مثل: "Public doctors are viewable by all".',
      );
    }

    return Doctor.fromJson(after);
  }

  // تحديث بيانات الطبيب (ويرجع السجل بعد التحديث للتأكد من الحفظ)
  Future<Doctor> updateDoctorProfile({
    required String doctorId,
    String? fullName,
    String? title,
    String? specialization,
    String? phone,
    String? bio,
    String? services,
    double? consultationFee,
    List<String>? galleryImageUrls,
    String? articleUrl,
    String? introVideoUrl,
    String? profileImageUrl,
    String? whatsappNumber,
    String? facebookUrl,
    String? location,
    String? qualifications,
    String? clinicAddress,
    String? geoLocation,
    String? workingHoursNotes,
    bool? emergency24h,
    String? emergencyPhone,
    bool? homeVisit,
    bool? isBookingEnabled,
    bool? isPayAtBookingEnabled,
    bool? isCancelBookingEnabledAtPayment,
    String? paymentMethod,
    String? paymentAccount,
  }) async {
    try {
      final data = <String, dynamic>{};

      bool hasText(String? v) => v != null && v.trim().isNotEmpty;

      if (hasText(fullName)) data['full_name'] = fullName!.trim();
      if (hasText(title)) data['title'] = title!.trim();
      if (hasText(specialization)) {
        data['specialization'] = specialization!.trim();
      }
      if (hasText(phone)) data['phone'] = _normalizePhoneToE164(phone!);
      if (hasText(bio)) data['bio'] = bio!.trim();
      if (hasText(services)) data['services'] = services!.trim();
      if (consultationFee != null) data['consultation_fee'] = consultationFee;
      if (galleryImageUrls != null) {
        data['gallery_image_urls'] = galleryImageUrls;
      }

      if (hasText(articleUrl)) data['article_url'] = articleUrl!.trim();
      // Allow clearing by passing an empty string.
      if (introVideoUrl != null) {
        final v = introVideoUrl.trim();
        data['intro_video_url'] = v.isEmpty ? null : v;
      }
      if (hasText(profileImageUrl)) {
        data['profile_image_url'] = profileImageUrl!.trim();
      }
      if (hasText(whatsappNumber)) {
        data['whatsapp_number'] = whatsappNumber!.trim();
      }
      if (hasText(facebookUrl)) data['facebook_url'] = facebookUrl!.trim();
      // Store "area" in the existing `location` column. Allow clearing.
      if (location != null) {
        final v = location.trim();
        data['location'] = v.isEmpty ? null : v;
      }
      if (hasText(qualifications)) {
        data['qualifications'] = qualifications!.trim();
      }
      if (hasText(clinicAddress)) {
        data['clinic_address'] = clinicAddress!.trim();
      }
      if (hasText(geoLocation)) data['geo_location'] = geoLocation!.trim();
      if (hasText(workingHoursNotes)) {
        data['working_hours_notes'] = workingHoursNotes!.trim();
      }
      if (emergency24h != null) {
        data['emergency_24h'] = emergency24h;
      }
      if (emergencyPhone != null) {
        final v = emergencyPhone.trim();
        data['emergency_phone'] = v.isEmpty ? null : v;
      }
      if (homeVisit != null) {
        data['home_visit'] = homeVisit;
      }
      if (isBookingEnabled != null) {
        data['is_booking_enabled'] = isBookingEnabled;
      }
      if (isPayAtBookingEnabled != null) {
        data['is_pay_at_booking_enabled'] = isPayAtBookingEnabled;
      }
      if (isCancelBookingEnabledAtPayment != null) {
        data['is_cancel_booking_enabled_at_payment'] =
            isCancelBookingEnabledAtPayment;
      }

      // Allow clearing by passing an empty string.
      if (paymentMethod != null) {
        final v = paymentMethod.trim();
        data['payment_method'] = v.isEmpty ? null : v;
      }
      if (paymentAccount != null) {
        final v = paymentAccount.trim();
        data['payment_account'] = v.isEmpty ? null : v;
      }
      data['updated_at'] = DateTime.now().toIso8601String();

      Future<Map<String, dynamic>?> doUpdate(Map<String, dynamic> payload) {
        return _client
            .from('doctors')
            .update(payload)
            .eq('id', doctorId)
            .select()
            .maybeSingle();
      }

      Map<String, dynamic>? response;
      try {
        response = await doUpdate(data);
      } catch (e) {
        final msg = e.toString();

        // If schema migrations weren't applied yet, retry without new columns
        // to avoid blocking the whole profile save.
        final retryPayload = Map<String, dynamic>.from(data);
        var shouldRetry = false;

        if (_looksLikeMissingColumn(msg, 'is_booking_enabled')) {
          retryPayload.remove('is_booking_enabled');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'is_pay_at_booking_enabled')) {
          retryPayload.remove('is_pay_at_booking_enabled');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(
          msg,
          'is_cancel_booking_enabled_at_payment',
        )) {
          retryPayload.remove('is_cancel_booking_enabled_at_payment');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'payment_method')) {
          retryPayload.remove('payment_method');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'payment_account')) {
          retryPayload.remove('payment_account');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'working_hours_notes')) {
          retryPayload.remove('working_hours_notes');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'emergency_24h')) {
          retryPayload.remove('emergency_24h');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'emergency_phone')) {
          retryPayload.remove('emergency_phone');
          shouldRetry = true;
        }
        if (_looksLikeMissingColumn(msg, 'home_visit')) {
          retryPayload.remove('home_visit');
          shouldRetry = true;
        }

        if (!shouldRetry) rethrow;

        response = await doUpdate(retryPayload);
      }

      // إذا كانت النتيجة null فهذا يعني: إما لم يتم تحديث أي صف (RLS/فلتر) أو لا يوجد صف مطابق
      if (response == null) {
        final existing = await _client
            .from('doctors')
            .select()
            .eq('id', doctorId)
            .maybeSingle();

        if (existing == null) {
          throw Exception('لم يتم العثور على حساب الطبيب لتحديثه.');
        }

        // الصف موجود لكن UPDATE لم يُرجع شيئاً: غالباً RLS تمنع التعديل
        throw Exception(
          'تم رفض تحديث البيانات (تحقق من سياسات RLS لجدول doctors: يجب السماح للطبيب بتحديث صفه).',
        );
      }

      return Doctor.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DoctorWorkingHours>> getDoctorWorkingHours({
    required String doctorId,
  }) async {
    final rows =
        await _client
                .from('doctor_working_hours')
                .select()
                .eq('doctor_id', doctorId)
                .order('day_of_week')
            as List<dynamic>;

    return rows
        .whereType<Map<String, dynamic>>()
        .map(DoctorWorkingHours.fromJson)
        .toList();
  }

  Future<List<DoctorWorkingHours>> getCurrentDoctorWorkingHours() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <DoctorWorkingHours>[];
    return getDoctorWorkingHours(doctorId: user.id);
  }

  Future<void> upsertDoctorWorkingHours({
    required String doctorId,
    required List<DoctorWorkingHours> entries,
  }) async {
    final payload = entries.map((e) => e.toUpsertJson()).toList();
    await _client
        .from('doctor_working_hours')
        .upsert(payload, onConflict: 'doctor_id,day_of_week');
  }

  Future<void> createAppointment({
    required String doctorId,
    required String patientName,
    required String patientPhone,
    required DateTime appointmentDate,
    required TimeOfDay appointmentTime,
    String? notes,
    String? paymentReceiptUrl,
  }) async {
    final name = patientName.trim();
    final phone = patientPhone.trim();
    if (name.isEmpty) {
      throw Exception('يرجى إدخال اسم المريض.');
    }
    if (phone.isEmpty) {
      throw Exception('يرجى إدخال رقم الهاتف.');
    }

    final dateOnly = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    final timeStr =
        '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}:00';

    await _client.from('appointments').insert({
      'doctor_id': doctorId,
      'patient_name': name,
      'patient_phone': phone,
      'appointment_date': dateOnly.toIso8601String(),
      'appointment_time': timeStr,
      'notes': (notes ?? '').trim().isEmpty ? null : notes!.trim(),
      'payment_receipt_url': paymentReceiptUrl,
      'status': appointmentStatusPending,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByPatientPhone({
    required String patientPhone,
  }) async {
    final phone = patientPhone.trim();
    if (phone.isEmpty) return const <Map<String, dynamic>>[];

    final rows =
        await _client
                .from('appointments')
                .select()
                .eq('patient_phone', phone)
                .order('created_at', ascending: false)
            as List<dynamic>;

    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsForDoctor({
    required String doctorId,
    String? status,
  }) async {
    var query = _client.from('appointments').select().eq('doctor_id', doctorId);
    if (status != null && status.trim().isNotEmpty) {
      query = query.eq('status', status.trim());
    }

    final rows =
        await query.order('created_at', ascending: false) as List<dynamic>;
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> updateAppointmentStatus({
    required dynamic appointmentId,
    required String status,
  }) async {
    await _client
        .from('appointments')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointmentId);
  }

  // تحديث طلب الحجز مع رد الطبيب والموعد المقترح
  Future<void> updateAppointmentWithDoctorResponse({
    required dynamic appointmentId,
    required String status,
    String? responseMessage,
    DateTime? suggestedDate,
    String? suggestedTime,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (responseMessage != null && responseMessage.trim().isNotEmpty) {
      data['doctor_response_message'] = responseMessage.trim();
    }

    if (suggestedDate != null) {
      data['suggested_date'] = DateTime(
        suggestedDate.year,
        suggestedDate.month,
        suggestedDate.day,
      ).toIso8601String();
    }

    if (suggestedTime != null && suggestedTime.trim().isNotEmpty) {
      data['suggested_time'] = suggestedTime.trim();
    }

    await _client.from('appointments').update(data).eq('id', appointmentId);
  }

  /// Patient flow: accept a suggested slot from the doctor and re-submit.
  ///
  /// - Sets `status` back to `pending`
  /// - Copies `suggested_date/time` into `appointment_date/time` when present
  /// - Clears `suggested_date/time` and `doctor_response_message`
  ///
  /// Note: Requires an RLS policy that allows the patient to update their
  /// appointment row (commonly by matching `patient_phone`).
  Future<void> resubmitAppointmentWithSuggestedSlot({
    required Map<String, dynamic> appointment,
  }) async {
    final appointmentId =
        appointment['id'] ??
        appointment['appointment_id'] ??
        appointment['appointmentId'];
    if (appointmentId == null) {
      throw Exception('معرّف الموعد غير موجود');
    }

    final DateTime? suggestedDate = _tryParseDate(
      appointment['suggested_date'],
    );
    final DateTime? currentDate = _tryParseDate(
      appointment['appointment_date'],
    );
    final dynamic suggestedTime = appointment['suggested_time'];
    final dynamic currentTime = appointment['appointment_time'];

    final DateTime? newDate = suggestedDate ?? currentDate;
    final dynamic newTime = suggestedTime ?? currentTime;

    if (newDate == null &&
        (newTime == null || newTime.toString().trim().isEmpty)) {
      throw Exception('لا يوجد موعد مقترح لإعادة الإرسال');
    }

    final existingNotes = (appointment['notes'] ?? '').toString().trim();
    const marker = 'تمت الموافقة على الموعد المقترح من الطبيب.';
    final mergedNotes = existingNotes.isEmpty
        ? marker
        : (existingNotes.contains(marker)
              ? existingNotes
              : '$existingNotes\n$marker');

    final data = <String, dynamic>{
      'status': appointmentStatusPending,
      'updated_at': DateTime.now().toIso8601String(),
      'suggested_date': null,
      'suggested_time': null,
      'doctor_response_message': null,
      'notes': mergedNotes,
    };

    if (newDate != null) {
      data['appointment_date'] = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
      ).toIso8601String();
    }

    if (newTime != null && newTime.toString().trim().isNotEmpty) {
      data['appointment_time'] = newTime.toString().trim();
    }

    await _client.from('appointments').update(data).eq('id', appointmentId);
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Future<void> updateAppointmentPaymentReceiptUrl({
    required dynamic appointmentId,
    required String? paymentReceiptUrl,
  }) async {
    await _client
        .from('appointments')
        .update({
          'payment_receipt_url': paymentReceiptUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointmentId);
  }

  // تأكيد الدفع من قبل الطبيب
  Future<void> confirmPayment({required dynamic appointmentId}) async {
    await _client
        .from('appointments')
        .update({
          'payment_confirmed': true,
          'payment_confirmed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointmentId);
  }

  Future<Doctor?> getDoctorById({required String doctorId}) async {
    final response = await _client
        .from('doctors')
        .select()
        .eq('id', doctorId)
        .maybeSingle();
    if (response == null) return null;
    return Doctor.fromJson(response);
  }

  Future<Map<String, Doctor>> getDoctorsByIds({
    required List<String> doctorIds,
  }) async {
    final uniqueIds = doctorIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) return <String, Doctor>{};

    final rows =
        await _client.from('doctors').select().inFilter('id', uniqueIds)
            as List<dynamic>;

    final map = <String, Doctor>{};
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final doctor = Doctor.fromJson(row);
      map[doctor.id] = doctor;
    }
    return map;
  }

  // رفع صورة الملف الشخصي
  Future<String> uploadProfileImage({
    required String doctorId,
    required File imageFile,
  }) async {
    try {
      final fileName =
          'doctor_$doctorId${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$doctorId/$fileName';

      // قراءة bytes الصورة
      final bytes = await imageFile.readAsBytes();

      // رفع الصورة
      await _client.storage
          .from(_doctorsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // الحصول على رابط الصورة العام
      final imageUrl = _client.storage.from(_doctorsBucket).getPublicUrl(path);

      developer.log(
        'Image uploaded successfully to: $path',
        name: 'DoctorDatabaseService',
      );
      developer.log('Public URL: $imageUrl', name: 'DoctorDatabaseService');

      return imageUrl;
    } catch (e) {
      developer.log(
        'Error in uploadProfileImage',
        name: 'DoctorDatabaseService',
        error: e,
      );

      final msg = e.toString();
      if (msg.contains('Bucket not found') ||
          msg.contains('bucket') && msg.contains('not found')) {
        throw Exception(
          'خطأ: لم يتم العثور على Storage bucket باسم "$_doctorsBucket" داخل مشروع Supabase. '
          'اذهب إلى Storage ثم أنشئ bucket بالاسم "$_doctorsBucket" (حروف صغيرة تماماً) أو عدّل الاسم في الكود.',
        );
      }

      rethrow;
    }
  }

  Future<String> uploadPaymentReceipt({required File imageFile}) async {
    try {
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'payment_receipts/$fileName';

      final bytes = await imageFile.readAsBytes();

      await _client.storage
          .from(_doctorsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final imageUrl = _client.storage.from(_doctorsBucket).getPublicUrl(path);

      developer.log(
        'Payment receipt uploaded successfully to: $path',
        name: 'DoctorDatabaseService',
      );

      return imageUrl;
    } catch (e) {
      developer.log(
        'Error in uploadPaymentReceipt',
        name: 'DoctorDatabaseService',
        error: e,
      );

      final msg = e.toString();
      if (msg.contains('Bucket not found') ||
          (msg.contains('bucket') && msg.contains('not found'))) {
        throw Exception(
          'خطأ: لم يتم العثور على Storage bucket باسم "$_doctorsBucket" داخل Supabase. '
          'اذهب إلى Storage وأنشئ bucket باسم "$_doctorsBucket" أو عدّل الاسم في الكود.',
        );
      }

      // Supabase Storage may reject uploads when policies disallow insert/update on storage.objects.
      if (msg.contains('row-level security') ||
          msg.contains('RLS') ||
          msg.contains('Unauthorized') ||
          msg.contains('403') ||
          msg.contains('not authorized')) {
        throw Exception(
          'تعذر رفع إيصال الدفع بسبب صلاحيات التخزين في Supabase. '
          'تأكد من سياسات Storage للـ bucket "$_doctorsBucket" وأن المستخدم الحالي مسموح له بالرفع إلى المسار "payment_receipts/".',
        );
      }

      rethrow;
    }
  }

  Future<String> uploadGalleryImage({
    required String doctorId,
    required File imageFile,
  }) async {
    try {
      final fileName =
          'gallery_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final path = '$doctorId/$_galleryFolder/$fileName';

      final bytes = await imageFile.readAsBytes();

      await _client.storage
          .from(_doctorsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final imageUrl = _client.storage.from(_doctorsBucket).getPublicUrl(path);

      developer.log(
        'Gallery image uploaded successfully to: $path',
        name: 'DoctorDatabaseService',
      );

      return imageUrl;
    } catch (e) {
      developer.log(
        'Error in uploadGalleryImage',
        name: 'DoctorDatabaseService',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> uploadIntroVideo({
    required String doctorId,
    required File videoFile,
  }) async {
    try {
      final bytesLength = await videoFile.length();
      if (bytesLength > _maxIntroVideoBytes) {
        throw Exception('حجم الفيديو أكبر من 30 ميجا.');
      }

      final originalName = videoFile.path.split('/').last;
      String ext = '';
      final dot = originalName.lastIndexOf('.');
      if (dot != -1 && dot < originalName.length - 1) {
        ext = originalName.substring(dot).toLowerCase();
      }
      if (ext.isEmpty || ext.length > 6) {
        ext = '.mp4';
      }

      final fileName = 'intro_${DateTime.now().millisecondsSinceEpoch}$ext';
      final path = '$doctorId/$_introVideoFolder/$fileName';

      final bytes = await videoFile.readAsBytes();

      // Best-effort content type.
      final contentType = () {
        switch (ext) {
          case '.mp4':
            return 'video/mp4';
          case '.mov':
            return 'video/quicktime';
          case '.webm':
            return 'video/webm';
          case '.m3u8':
            return 'application/x-mpegURL';
          default:
            return 'video/mp4';
        }
      }();

      await _client.storage
          .from(_doctorsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final url = _client.storage.from(_doctorsBucket).getPublicUrl(path);

      developer.log(
        'Intro video uploaded successfully to: $path',
        name: 'DoctorDatabaseService',
      );

      return url;
    } catch (e) {
      developer.log(
        'Error in uploadIntroVideo',
        name: 'DoctorDatabaseService',
        error: e,
      );
      rethrow;
    }
  }

  // الحصول على قائمة جميع الأطباء
  Future<List<Doctor>> getAllDoctors() async {
    try {
      final response = await _client
          .from('doctors')
          .select()
          .eq('is_published', true);

      return (response as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // البحث عن أطباء حسب التخصص
  Future<List<Doctor>> getDoctorsBySpecialization(String specialization) async {
    try {
      final normalized = _normalizeSpecialtyLabel(specialization);
      final aliases = _specialtyAliases(normalized);

      final response = await _client
          .from('doctors')
          .select()
          .inFilter('specialization', aliases)
          .eq('is_published', true);

      final list = (response as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fallback: handle minor text mismatches (extra words/parentheses).
      if (list.isNotEmpty || normalized.isEmpty) return list;

      final fallback = await _client
          .from('doctors')
          .select()
          .ilike('specialization', '%$normalized%')
          .eq('is_published', true);

      return (fallback as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // البحث عن طبيب حسب الاسم
  Future<List<Doctor>> searchDoctorsByName(String name) async {
    try {
      final response = await _client
          .from('doctors')
          .select()
          .ilike('full_name', '%$name%')
          .eq('is_published', true);

      return (response as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على الأطباء حسب التخصص
  Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    try {
      final normalized = _normalizeSpecialtyLabel(specialty);
      final aliases = _specialtyAliases(normalized);

      final response = await _client
          .from('doctors')
          .select()
          .inFilter('specialization', aliases)
          .eq('is_published', true);

      final list = (response as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fallback: handle minor text mismatches (extra words/parentheses).
      if (list.isNotEmpty || normalized.isEmpty) return list;

      final fallback = await _client
          .from('doctors')
          .select()
          .ilike('specialization', '%$normalized%')
          .eq('is_published', true);

      return (fallback as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // حذف حساب الطبيب (للمدير فقط)
  Future<void> deleteDoctorAccount(String doctorId) async {
    try {
      await _client.from('doctors').delete().eq('id', doctorId);
    } catch (e) {
      rethrow;
    }
  }

  // طلب حذف الحساب (للطبيب - يحتاج موافقة المدير)
  Future<void> requestDeleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً.');

    await _client
        .from('doctors')
        .update({
          'delete_requested': true,
          'delete_requested_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // طلب حذف الحساب بـ doctorId محدد
  Future<void> requestAccountDeletion({required String doctorId}) async {
    await _client
        .from('doctors')
        .update({
          'delete_requested': true,
          'delete_requested_at': DateTime.now().toIso8601String(),
        })
        .eq('id', doctorId);
  }

  // إلغاء طلب حذف الحساب
  Future<void> cancelDeleteRequest() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً.');

    await _client
        .from('doctors')
        .update({'delete_requested': false, 'delete_requested_at': null})
        .eq('id', user.id);
  }

  // طلب نشر صفحة الطبيب (يرسل طلباً للمدير للموافقة)
  Future<void> requestPublishForCurrentDoctor() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً.');

    await _client
        .from('doctors')
        .update({
          'publish_requested': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // إضافة تقييم للطبيب
  Future<void> addDoctorRating({
    required String doctorId,
    required double rating,
  }) async {
    try {
      // الحصول على التقييم الحالي
      final doctorData = await _client
          .from('doctors')
          .select('rating, rating_count')
          .eq('id', doctorId)
          .single();

      final currentRating = (doctorData['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (doctorData['rating_count'] as int?) ?? 0;

      // حساب التقييم الجديد
      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + rating) / newCount;

      // تحديث التقييم
      await _client
          .from('doctors')
          .update({
            'rating': newRating,
            'rating_count': newCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Doctor Questions & Answers ============

  // إضافة سؤال من مريض
  Future<void> addDoctorQuestion({
    required String doctorId,
    required String patientName,
    String? patientPhone,
    required String question,
  }) async {
    try {
      await _client.from('doctor_questions').insert({
        'doctor_id': doctorId,
        'patient_name': patientName.trim(),
        'patient_phone': patientPhone?.trim(),
        'question': question.trim(),
        'is_answered': false,
      });
    } catch (e) {
      throw Exception('خطأ في إرسال السؤال: $e');
    }
  }

  // جلب الأسئلة المُجاب عليها فقط (للعرض العام)
  Future<List<Map<String, dynamic>>> getAnsweredQuestions({
    required String doctorId,
  }) async {
    try {
      final rows =
          await _client
                  .from('doctor_questions')
                  .select()
                  .eq('doctor_id', doctorId)
                  .eq('is_answered', true)
                  .order('answered_at', ascending: false)
              as List<dynamic>;

      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('خطأ في جلب الأسئلة: $e');
    }
  }

  // جلب كل أسئلة الطبيب (للطبيب في ملفه الشخصي)
  Future<List<Map<String, dynamic>>> getDoctorAllQuestions({
    required String doctorId,
  }) async {
    try {
      final rows =
          await _client
                  .from('doctor_questions')
                  .select()
                  .eq('doctor_id', doctorId)
                  .order('created_at', ascending: false)
              as List<dynamic>;

      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('خطأ في جلب الأسئلة: $e');
    }
  }

  // الإجابة على سؤال
  Future<void> answerQuestion({
    required dynamic questionId,
    required String answer,
  }) async {
    try {
      final response = await _client
          .from('doctor_questions')
          .update({
            'answer': answer.trim(),
            'is_answered': true,
            'answered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questionId)
          .select();

      if (response.isEmpty) {
        throw Exception(
          'لم يتم تحديث السؤال. تحقق من الصلاحيات في Supabase RLS.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // حذف سؤال
  Future<void> deleteQuestion({required dynamic questionId}) async {
    try {
      await _client.from('doctor_questions').delete().eq('id', questionId);
    } catch (e) {
      throw Exception('خطأ في حذف السؤال: $e');
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('خطأ في تسجيل الخروج: $e');
    }
  }
}
