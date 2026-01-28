import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // يجب استبدال هذه القيم بـ URL و Anon Key من لوحة تحكم Supabase
  // اتبع هذه الخطوات:
  // 1. اذهب إلى https://supabase.com
  // 2. أنشئ مشروع جديد
  // 3. انسخ Project URL من Settings -> API
  // 4. انسخ anon (public) key من Settings -> API
  
  static const String supabaseUrl = 'https://wwsygshxuejnghvocnke.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_sXh_vtdgbwukZnXkQMXeSw_nTY1L10x';
  
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    // تخطي التهيئة إذا كانت البيانات وهمية (للاختبارات)
    if (supabaseUrl == 'YOUR_SUPABASE_URL' || supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY') {
      debugPrint('⚠️ تحذير: Supabase لم يتم تكوينه. استخدم بيانات اعتماد فعلية للإنتاج.');
      _initialized = false;
      return;
    }
    
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة Supabase: $e');
      _initialized = false;
    }
  }

  // الحصول على عميل Supabase
  static SupabaseClient get client => Supabase.instance.client;

  // التحقق من حالة المستخدم
  static bool get isUserLoggedIn => Supabase.instance.client.auth.currentUser != null;

  // الحصول على بيانات المستخدم الحالي
  static String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
}
