import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HospitalMediaService {
  final _supabase = Supabase.instance.client;

  // يجب إنشاء bucket بنفس الاسم في Supabase Storage.
  static const String bucket = 'hospitals-images';

  Future<String> uploadImage(XFile file, String folder) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً (لا يوجد مستخدم حالي)');
      }

      final rawName = (file.name.isNotEmpty ? file.name : file.path);
      final hasDot = rawName.contains('.') && !rawName.endsWith('.');
      final ext = hasDot ? rawName.split('.').last.toLowerCase() : 'jpg';

      final fileName =
          '${user.id}/$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';

      String contentType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      final bytes = await file.readAsBytes();

      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } on StorageException catch (e) {
      debugPrint(
        '❌ StorageException uploading image (bucket=$bucket, folder=$folder): ${e.message}',
      );
      throw Exception('خطأ رفع الصور (Storage): ${e.message}');
    } on PostgrestException catch (e) {
      debugPrint(
        '❌ PostgrestException uploading image (bucket=$bucket, folder=$folder): ${e.message}',
      );
      throw Exception('خطأ رفع الصور (DB): ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading image (bucket=$bucket, folder=$folder): $e');
      }
      throw Exception('خطأ رفع الصور: $e');
    }
  }
}
