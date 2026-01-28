import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/doctor_model.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Doctor> getDoctorByIdForAdmin(String doctorId) async {
    try {
      final row = await _supabase
          .from('doctors')
          .select()
          .eq('id', doctorId)
          .maybeSingle();

      if (row == null) {
        throw Exception('لم يتم العثور على الطبيب (قد يكون السجل محذوفاً).');
      }

      return Doctor.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw Exception('فشل تحميل صفحة الطبيب للمعاينة: ${e.toString()}');
    }
  }

  String _normalizePhoneToE164(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    // Keep only digits
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return trimmed;

    // Convert 00 international prefix to +
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // Default: Egypt numbers
    // Local: 01XXXXXXXXX (11 digits) -> +201XXXXXXXXX
    if (digits.startsWith('0') && digits.length == 11) {
      return '+20${digits.substring(1)}';
    }

    // Already country-prefixed without plus: 201XXXXXXXXX
    if (digits.startsWith('20') && digits.length == 12) {
      return '+$digits';
    }

    // If user already typed +... keep it as +<digits>
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }

    // Fallback: prefix plus
    return '+$digits';
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  String _formatSupabaseError(Object error) {
    if (error is PostgrestException) {
      final details =
          (error.details == null || error.details.toString().isEmpty)
          ? ''
          : '\nDetails: ${error.details}';
      final hint = (error.hint == null || error.hint.toString().isEmpty)
          ? ''
          : '\nHint: ${error.hint}';
      return '${error.message}$details$hint';
    }
    return error.toString();
  }

  Future<void> _assertDoctorNotExists({
    required String email,
    String? licenseNumber,
    String? phone,
  }) async {
    // بناء الشروط بناءً على ما هو متاح
    final conditions = <String>['email.eq.$email'];

    if (licenseNumber != null && licenseNumber.trim().isNotEmpty) {
      conditions.add('license_number.eq.$licenseNumber');
    }

    String? normalizedPhone;
    if (phone != null && phone.trim().isNotEmpty) {
      normalizedPhone = _normalizePhoneToE164(phone);
      conditions.add('phone.eq.$normalizedPhone');
    }

    final existing = await _supabase
        .from('doctors')
        .select('id,email,license_number,phone')
        .or(conditions.join(','));

    final rows = List<Map<String, dynamic>>.from(existing);
    if (rows.isEmpty) return;

    final emailExists = rows.any(
      (r) => (r['email'] as String?)?.toLowerCase() == email.toLowerCase(),
    );
    final licenseExists =
        licenseNumber != null && licenseNumber.trim().isNotEmpty
        ? rows.any((r) => (r['license_number'] as String?) == licenseNumber)
        : false;
    final phoneExists = normalizedPhone != null
        ? rows.any((r) {
            final stored = (r['phone'] as String?) ?? '';
            return _normalizePhoneToE164(stored) == normalizedPhone;
          })
        : false;

    if (emailExists && licenseExists) {
      throw Exception('هذا البريد الإلكتروني ورقم الترخيص مستخدمان بالفعل');
    }
    if (emailExists) {
      throw Exception('هذا البريد الإلكتروني مستخدم بالفعل');
    }
    if (licenseExists) {
      throw Exception('رقم الترخيص مستخدم بالفعل');
    }
    if (phoneExists) {
      throw Exception('رقم الهاتف مستخدم بالفعل');
    }
  }

  // تسجيل دخول المدير
  Future<AuthResponse> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // التحقق من أن المستخدم مدير
      final isAdmin = await _isUserAdmin(response.user!.id);
      if (!isAdmin) {
        await _supabase.auth.signOut();
        throw Exception('هذا الحساب ليس حساب مدير');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // التحقق من أن المستخدم مدير
  Future<bool> _isUserAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('admins')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // إنشاء حساب طبيب جديد (فقط للمدير)
  Future<Map<String, dynamic>> createDoctorAccount({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
    String? phone,
    String? licenseNumber,
  }) async {
    try {
      // حفظ بيانات المدير الحالي
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('يجب تسجيل دخول المدير أولاً');
      }

      // فحص مسبق لتفادي إنشاء مستخدم Auth بدون سجل في جدول doctors
      // (مهم جداً لأن حذف المستخدم من Auth يتطلب Admin API)
      await _assertDoctorNotExists(
        email: email,
        licenseNumber: licenseNumber,
        phone: phone,
      );

      final normalizedPhone = phone != null && phone.trim().isNotEmpty
          ? _normalizePhoneToE164(phone)
          : null;

      // إنشاء حساب الطبيب عبر عميل منفصل حتى لا تتغير جلسة المدير
      final isolatedAuthClient = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          // ملاحظة: إنشاء SupabaseClient بشكل مباشر لا يزوّد gotrue بـ asyncStorage،
          // وبالتالي تدفق PKCE يسبب assertion. نستخدم implicit هنا لتفادي ذلك.
          authFlowType: AuthFlowType.implicit,
        ),
      );

      AuthResponse response;
      try {
        response = await isolatedAuthClient.auth.signUp(
          email: email,
          password: password,
        );
      } on AuthApiException catch (e) {
        if (e.statusCode == '422' && e.code == 'user_already_exists') {
          throw Exception(
            'هذا البريد الإلكتروني مسجّل بالفعل في نظام تسجيل الدخول.\n'
            'الحل: استخدم بريد مختلف، أو احذف المستخدم من Supabase Dashboard → Authentication → Users ثم جرّب مرة أخرى.',
          );
        }
        rethrow;
      }

      if (response.user == null) {
        throw Exception('فشل إنشاء حساب المصادقة');
      }

      final userId = response.user!.id;

      // إضافة بيانات الطبيب في جدول doctors بجلسة المدير (حتى لو signUp لم ينشئ session)
      try {
        final insertData = {
          'id': userId,
          'email': email,
          'full_name': fullName,
          'specialization': specialization,
          // مهم: بعض قواعد البيانات تضع DEFAULT '' لحقول مثل phone/license_number.
          // مع وجود unique index (مثل idx_doctors_phone_e164) هذا يسبب تعارضاً
          // عند إنشاء أكثر من طبيب بدون رقم هاتف. لذلك نرسل NULL صراحةً.
          'phone': normalizedPhone,
          'license_number':
              (licenseNumber != null && licenseNumber.trim().isNotEmpty)
              ? licenseNumber
              : null,
        };

        await _supabase.from('doctors').insert(insertData);
      } catch (e) {
        final insertError = _formatSupabaseError(e);
        final lower = insertError.toLowerCase();

        // Unique constraint mapping (common in this project)
        if (normalizedPhone != null &&
            lower.contains('idx_doctors_phone_e164')) {
          try {
            final normalizedDigits = _digitsOnly(normalizedPhone);
            final tailLen = normalizedDigits.length >= 8
                ? 8
                : normalizedDigits.length;
            final tail = normalizedDigits.substring(
              normalizedDigits.length - tailLen,
            );

            final matches = await _supabase
                .from('doctors')
                .select('full_name,email,phone')
                .like('phone', '%$tail');

            final rows = List<Map<String, dynamic>>.from(matches);
            if (rows.isNotEmpty) {
              final first = rows.first;
              throw Exception(
                'رقم الهاتف مستخدم بالفعل (قد يكون مكتوب بصيغة مختلفة).\n'
                'الرقم المدخل بعد التطبيع: $normalizedPhone\n'
                'موجود عند: ${first['full_name']} (${first['email']})\n'
                'الرقم المخزّن: ${first['phone']}',
              );
            }
          } catch (_) {
            // ignore lookup errors
          }

          throw Exception(
            'رقم الهاتف مستخدم بالفعل.\n'
            'ملاحظة: النظام يوحّد الأرقام لصيغة دولية مثل +2010xxxxxxx، لذلك 010... و0020... و+20... قد تُعتبر نفس الرقم.',
          );
        }
        if (licenseNumber != null &&
            lower.contains('license') &&
            lower.contains('duplicate')) {
          try {
            final existing = await _supabase
                .from('doctors')
                .select('full_name,email,license_number')
                .eq('license_number', licenseNumber)
                .maybeSingle();
            if (existing != null) {
              throw Exception(
                'رقم الترخيص مستخدم بالفعل (${existing['license_number']}).\n'
                'مستخدم عند: ${existing['full_name']} (${existing['email']}).',
              );
            }
          } catch (_) {
            // ignore lookup errors
          }
          throw Exception('رقم الترخيص مستخدم بالفعل');
        }
        if (lower.contains('email') && lower.contains('duplicate')) {
          throw Exception('هذا البريد الإلكتروني مستخدم بالفعل');
        }

        if (lower.contains('row-level security') ||
            lower.contains('rls') ||
            lower.contains('permission denied') ||
            lower.contains('not allowed')) {
          throw Exception(
            'تم إنشاء الحساب لكن فشل حفظ البيانات بسبب صلاحيات قاعدة البيانات (RLS).\n'
            'نفّذ سكربت السياسات الموجود في fix_doctor_policies.sql ثم جرّب مرة أخرى.\n'
            'التفاصيل: $insertError',
          );
        }
        throw Exception('تم إنشاء الحساب لكن فشل حفظ البيانات: $insertError');
      }

      return {'success': true, 'userId': userId, 'email': email};
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على قائمة جميع الأطباء
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select(
            'id,full_name,email,phone,specialization,is_published,publish_requested,delete_requested,delete_requested_at,created_at',
          )
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل تحميل قائمة الأطباء: ${e.toString()}');
    }
  }

  // قبول طلب نشر صفحة الطبيب
  Future<void> approvePublishRequest(String doctorId) async {
    try {
      // Use list-based select to avoid PostgREST 406 (PGRST116) when 0 rows.
      final response = await _supabase
          .from('doctors')
          .update({
            'is_published': true,
            'publish_requested': false,
            'published_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId)
          .select('id,is_published,publish_requested,published_at');

      final updatedRows = List<Map<String, dynamic>>.from(response);

      // With RLS, a denied UPDATE commonly results in 0 affected rows.
      if (updatedRows.isEmpty) {
        // Distinguish between "row not found" and "no permission".
        final exists = await _supabase
            .from('doctors')
            .select('id')
            .eq('id', doctorId)
            .maybeSingle();

        if (exists == null) {
          throw Exception(
            'لم يتم تحديث حالة النشر لأن سجل الطبيب غير موجود (doctorId غير صحيح أو السجل محذوف).',
          );
        }

        throw Exception(
          'لم يتم تحديث حالة النشر (0 rows) رغم أن سجل الطبيب موجود.\n'
          'هذا يعني غالباً أن صلاحيات RLS تمنع المدير من UPDATE.\n'
          'الحل: نفّذ fix_doctor_policies.sql (أو admin_setup.sql) وتأكد أن UUID المدير موجود في جدول admins.',
        );
      }

      final updated = updatedRows.first;
      if (updated['is_published'] != true) {
        throw Exception(
          'تم تنفيذ الطلب لكن لم تصبح الحالة "منشور". تحقق من سياسات RLS أو أي triggers على جدول doctors.',
        );
      }
    } catch (e) {
      throw Exception('فشل قبول طلب النشر: ${e.toString()}');
    }
  }

  // رفض طلب حذف الحساب
  Future<void> rejectDeleteRequest(String doctorId) async {
    try {
      await _supabase
          .from('doctors')
          .update({
            'delete_requested': false,
            'delete_requested_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);
    } catch (e) {
      throw Exception('فشل رفض طلب الحذف: ${e.toString()}');
    }
  }

  // حذف حساب طبيب
  Future<void> deleteDoctor(String doctorId) async {
    try {
      // حذف من جدول الأطباء فقط
      // ملاحظة: حذف المستخدم من Authentication يتطلب Edge Function
      await _supabase.from('doctors').delete().eq('id', doctorId);
    } catch (e) {
      throw Exception('فشل حذف الطبيب: ${e.toString()}');
    }
  }

  // إعادة تعيين كلمة مرور طبيب
  Future<void> resetDoctorPassword({
    required String doctorId,
    required String newPassword,
  }) async {
    try {
      // الحصول على email الطبيب
      final doctorData = await _supabase
          .from('doctors')
          .select('email')
          .eq('id', doctorId)
          .single();

      // إرسال رابط إعادة تعيين كلمة المرور
      await _supabase.auth.resetPasswordForEmail(doctorData['email']);

      throw Exception('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريد الطبيب');
    } catch (e) {
      throw Exception('فشل إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  // التحقق من أن المستخدم الحالي مدير
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      return await _isUserAdmin(user.id);
    } catch (e) {
      return false;
    }
  }

  // إرسال رسالة من المدير إلى طبيب
  Future<void> sendMessageToDoctor({
    required String doctorId,
    required String title,
    required String message,
  }) async {
    try {
      final adminUser = _supabase.auth.currentUser;
      if (adminUser == null) {
        throw Exception('يجب تسجيل الدخول كمدير');
      }

      // التحقق من أن المستخدم مدير
      final isAdmin = await _isUserAdmin(adminUser.id);
      if (!isAdmin) {
        throw Exception('غير مصرح لك بإرسال الرسائل');
      }

      // إنشاء جدول الرسائل إذا لم يكن موجوداً
      await _supabase.from('admin_messages').insert({
        'doctor_id': doctorId,
        'admin_id': adminUser.id,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل إرسال الرسالة: ${e.toString()}');
    }
  }

  // جلب رسائل طبيب معين
  Future<List<Map<String, dynamic>>> getDoctorMessages(String doctorId) async {
    try {
      final messages = await _supabase
          .from('admin_messages')
          .select('*')
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      throw Exception('فشل جلب الرسائل: ${e.toString()}');
    }
  }

  // تحديد رسالة كمقروءة
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('admin_messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('فشل تحديث حالة الرسالة: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getMessageReplies(String messageId) async {
    try {
      final rows = await _supabase
          .from('admin_message_replies')
          .select('*')
          .eq('message_id', messageId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      throw Exception('فشل جلب الردود: ${e.toString()}');
    }
  }

  /// إرسال رد من الطبيب إلى المدير على رسالة محددة.
  Future<void> sendDoctorReply({
    required String messageId,
    required String reply,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // Load the message to determine admin_id/doctor_id and validate ownership.
      final msg = await _supabase
          .from('admin_messages')
          .select('id,doctor_id,admin_id')
          .eq('id', messageId)
          .single();

      final doctorId = (msg['doctor_id'] ?? '').toString();
      final adminId = (msg['admin_id'] ?? '').toString();
      if (doctorId.isEmpty || adminId.isEmpty) {
        throw Exception('تعذر تحديد بيانات الرسالة');
      }

      if (doctorId != user.id) {
        throw Exception('غير مصرح لك بالرد على هذه الرسالة');
      }

      await _supabase.from('admin_message_replies').insert({
        'message_id': messageId,
        'doctor_id': doctorId,
        'admin_id': adminId,
        'reply': reply.trim(),
        'is_read_by_admin': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل إرسال الرد: ${e.toString()}');
    }
  }

  /// صندوق وارد المدير: ردود الأطباء.
  Future<List<Map<String, dynamic>>> getAdminReplies() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول كمدير');
      }

      // Join doctor name + message title for display.
      final rows = await _supabase
          .from('admin_message_replies')
          .select(
            'id,reply,is_read_by_admin,created_at,message_id,doctor_id,admin_id,doctors(full_name,profile_image_url),admin_messages(title)',
          )
          .eq('admin_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      throw Exception('فشل تحميل الردود: ${e.toString()}');
    }
  }

  Future<void> markReplyAsReadByAdmin(String replyId) async {
    try {
      await _supabase
          .from('admin_message_replies')
          .update({'is_read_by_admin': true})
          .eq('id', replyId);
    } catch (e) {
      throw Exception('فشل تحديث حالة الرد: ${e.toString()}');
    }
  }
}
