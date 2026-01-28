import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

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

  Future<void> _assertDoctorNotExists({
    required String email,
    required String licenseNumber,
    required String phone,
  }) async {
    final normalizedPhone = _normalizePhoneToE164(phone);

    final existing = await _client
        .from('doctors')
        .select('id,email,license_number,phone')
        .or(
          'email.eq.$email,license_number.eq.$licenseNumber,phone.eq.$normalizedPhone',
        );

    final rows = List<Map<String, dynamic>>.from(existing);
    if (rows.isEmpty) return;

    final emailExists = rows.any(
      (r) => (r['email'] as String?)?.toLowerCase() == email.toLowerCase(),
    );
    final licenseExists = rows.any(
      (r) => (r['license_number'] as String?) == licenseNumber,
    );
    final phoneExists = rows.any((r) {
      final stored = (r['phone'] as String?) ?? '';
      return _normalizePhoneToE164(stored) == normalizedPhone;
    });

    if (emailExists) throw Exception('هذا البريد الإلكتروني مستخدم بالفعل');
    if (licenseExists) throw Exception('رقم الترخيص مستخدم بالفعل');
    if (phoneExists) throw Exception('رقم الهاتف مستخدم بالفعل');
  }

  // تسجيل دخول الطبيب
  Future<AuthResponse> signInDoctor({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // إنشاء حساب جديد للطبيب
  Future<AuthResponse> signUpDoctor({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
    required String phone,
    required String licenseNumber,
  }) async {
    try {
      final normalizedPhone = _normalizePhoneToE164(phone);

      // فحص مسبق لتفادي إنشاء مستخدم Auth بدون سجل في جدول doctors
      await _assertDoctorNotExists(
        email: email,
        licenseNumber: licenseNumber,
        phone: normalizedPhone,
      );

      AuthResponse response;
      try {
        response = await _client.auth.signUp(email: email, password: password);
      } on AuthApiException catch (e) {
        if (e.statusCode == '422' && e.code == 'user_already_exists') {
          throw Exception('هذا البريد الإلكتروني مسجّل بالفعل');
        }
        rethrow;
      }

      if (response.user != null) {
        // حفظ بيانات الطبيب الإضافية في جدول doctors
        try {
          await _client.from('doctors').insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'specialization': specialization,
            'phone': normalizedPhone,
            'license_number': licenseNumber,
            // Newly created doctors are not visible in specialty lists until approved.
            // Setting this helps admins see the request without extra steps.
            'publish_requested': true,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('idx_doctors_phone_e164')) {
            try {
              final normalizedDigits = _digitsOnly(normalizedPhone);
              final tailLen = normalizedDigits.length >= 8
                  ? 8
                  : normalizedDigits.length;
              final tail = normalizedDigits.substring(
                normalizedDigits.length - tailLen,
              );

              final matches = await _client
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
            throw Exception('رقم الهاتف مستخدم بالفعل');
          }
          if (msg.contains('license') && msg.contains('duplicate')) {
            try {
              final existing = await _client
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
          if (msg.contains('email') && msg.contains('duplicate')) {
            throw Exception('هذا البريد الإلكتروني مستخدم بالفعل');
          }
          rethrow;
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على المستخدم الحالي
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // التحقق من تسجيل دخول المستخدم
  bool isUserLoggedIn() {
    return _client.auth.currentUser != null;
  }

  // إرسال رسالة إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على جلسة المستخدم الحالية
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }
}
