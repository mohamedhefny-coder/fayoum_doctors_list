import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:io';
import '../models/doctor_model.dart';
import '../models/doctor_working_hours.dart';
import '../services/doctor_database_service.dart';
import '../widgets/doctor_summary_card.dart';
import '../constants/fayoum_locations.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_detail_screen.dart';
import 'doctor_messages_screen.dart';
import 'intro_video_player_screen.dart';
import 'working_hours_schedule_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _dbService = DoctorDatabaseService();
  late Future<Doctor?> _doctorFuture;
  bool _isEditing = false;
  bool _isUploadingIntroVideo = false;
  bool _dataWasUpdated = false;
  bool _isCheckingVisibility = false;

  late TextEditingController _fullNameController;
  late TextEditingController _titleController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _servicesController;
  late TextEditingController _newServiceController;
  List<String> _servicesList = [];
  late TextEditingController _consultationFeeController;
  late TextEditingController _introVideoUrlController;
  late TextEditingController _whatsappController;
  late TextEditingController _facebookController;
  late TextEditingController _qualificationsController;
  late TextEditingController _addressController;
  late TextEditingController _geoLocationController;
  late TextEditingController _workingHoursNotesController;
  bool _emergency24Enabled = false;
  late TextEditingController _emergencyPhoneController;
  bool _homeVisitEnabled = false;
  // إعدادات الدفع عند الحجز (عرض داخل صفحة الملف الشخصي)
  bool _paymentInlineInitialized = false;
  bool _inlineUseVodafoneCash = false;
  bool _inlineUseInstaPay = false;
  late TextEditingController _inlineVodafoneCashController;
  late TextEditingController _inlineInstaPayController;
  String? _selectedSpecialization;

  String? _selectedCenter;
  String? _profileImageUrl;
  File? _selectedImage;
  List<String> _galleryImageUrls = <String>[];
  List<File> _newGalleryImages = <File>[];
  final ImagePicker _picker = ImagePicker();

  static const int _maxIntroVideoBytes = 30 * 1024 * 1024; // 30MB

  bool _looksLikeDirectVideoUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return false;
    if (u.contains('youtube.com') || u.contains('youtu.be')) return false;
    if (u.contains('vimeo.com')) return false;

    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.webm') ||
        u.endsWith('.m3u8');
  }

  Future<void> _previewIntroVideo(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    if (_looksLikeDirectVideoUrl(trimmed)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IntroVideoPlayerScreen(url: trimmed)),
      );
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickAndUploadIntroVideo(Doctor doctor) async {
    if (_isUploadingIntroVideo) return;
    try {
      final xfile = await _picker.pickVideo(source: ImageSource.gallery);
      if (xfile == null) return;

      final file = File(xfile.path);
      final lower = xfile.name.toLowerCase();
      final allowed =
          lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.webm');
      if (!allowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'صيغة الفيديو غير مدعومة. من فضلك اختر MP4 (يفضل H.264) أو MOV أو WEBM.',
            ),
          ),
        );
        return;
      }

      final bytes = await file.length();
      if (bytes > _maxIntroVideoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حجم الفيديو يجب ألا يزيد عن 30 ميجا.')),
        );
        return;
      }

      setState(() {
        _isUploadingIntroVideo = true;
      });

      final uploadedUrl = await _dbService.uploadIntroVideo(
        doctorId: doctor.id,
        videoFile: file,
      );

      await _dbService.updateDoctorProfile(
        doctorId: doctor.id,
        introVideoUrl: uploadedUrl,
      );

      if (!mounted) return;
      setState(() {
        _introVideoUrlController.text = uploadedUrl;
        _doctorFuture = _dbService.ensureCurrentDoctorProfile();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم رفع الفيديو بنجاح.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر رفع الفيديو: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingIntroVideo = false;
        });
      }
    }
  }

  Future<void> _clearIntroVideo(Doctor doctor) async {
    try {
      setState(() {
        _isUploadingIntroVideo = true;
      });

      await _dbService.updateDoctorProfile(
        doctorId: doctor.id,
        introVideoUrl: '',
      );

      if (!mounted) return;
      setState(() {
        _introVideoUrlController.text = '';
        _doctorFuture = _dbService.ensureCurrentDoctorProfile();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف رابط الفيديو.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حذف رابط الفيديو: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingIntroVideo = false;
        });
      }
    }
  }

  static const List<String> _weekDays = <String>[
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  final List<bool> _dayEnabled = List<bool>.filled(7, false);
  final List<TimeOfDay?> _dayStart = List<TimeOfDay?>.filled(7, null);
  final List<TimeOfDay?> _dayEnd = List<TimeOfDay?>.filled(7, null);

  bool _isBookingEnabled = true;

  final List<String> specializations = <String>[
    'طب عام',
    'أسنان',
    'علاج طبيعي',
    'تخاطب',
    'تحاليل طبية',
    'أشعة',
    'صيدلة',
    'تمريض',
    'باطنة (أمراض باطنة)',
    'قلب وأوعية دموية',
    'صدرية (أمراض الصدر)',
    'جهاز هضمي وكبد',
    'كُلى (أمراض الكلى)',
    'غدد صماء وسكر',
    'روماتيزم ومناعة',
    'حساسية ومناعة',
    'أمراض دم',
    'أورام',
    'جلدية وتناسلية',
    'أنف وأذن وحنجرة',
    'رمد',
    'جراحة عامة',
    'جراحة عظام',
    'جراحة قلب وصدر',
    'جراحة أوعية دموية',
    'جراحة الأورام',
    'جراحة المخ والأعصاب',
    'طب المخ والأعصاب',
    'جراحة تجميل',
    'جراحة أطفال',
    'جراحة مسالك بولية',
    'نساء وتوليد',
    'أطفال وحديثي الولادة',
    'مخ وأعصاب أطفال',
    'تغذية علاجية',
    'علاج الألم',
  ];

  @override
  void initState() {
    super.initState();
    _doctorFuture = _dbService.ensureCurrentDoctorProfile();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _titleController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _servicesController = TextEditingController();
    _newServiceController = TextEditingController();
    _consultationFeeController = TextEditingController();
    _introVideoUrlController = TextEditingController();
    _whatsappController = TextEditingController();
    _facebookController = TextEditingController();
    _qualificationsController = TextEditingController();
    _addressController = TextEditingController();
    _geoLocationController = TextEditingController();
    _workingHoursNotesController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _inlineVodafoneCashController = TextEditingController();
    _inlineInstaPayController = TextEditingController();
  }

  String? _parseLocationToCenter(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;

    // Accept both formats:
    // - "مركز - منطقة"
    // - "مركز|منطقة"
    final sep = t.contains('|') ? '|' : ' - ';
    final parts = t.split(sep).map((e) => e.trim()).where((e) => e.isNotEmpty);
    final list = parts.toList(growable: false);
    if (list.isEmpty) return null;
    return list[0];
  }

  void _applyWorkingHoursRows(List<DoctorWorkingHours> rows) {
    for (var i = 0; i < 7; i++) {
      _dayEnabled[i] = false;
      _dayStart[i] = null;
      _dayEnd[i] = null;
    }

    for (final row in rows) {
      final day = row.dayOfWeek;
      if (day < 0 || day > 6) continue;
      _dayEnabled[day] = row.isEnabled;
      _dayStart[day] = row.startTime;
      _dayEnd[day] = row.endTime;
    }
  }

  Future<void> _refreshWorkingHoursAndNotes({required String doctorId}) async {
    try {
      final hours = await _dbService.getDoctorWorkingHours(doctorId: doctorId);
      if (!mounted) return;
      setState(() {
        _applyWorkingHoursRows(hours);
      });

      // Refresh notes too (schedule screen can update them) without overwriting
      // other profile fields the user might be editing.
      final latestDoctor = await _dbService.ensureCurrentDoctorProfile();
      if (!mounted) return;
      setState(() {
        _workingHoursNotesController.text =
            latestDoctor.workingHoursNotes ?? '';
      });
    } catch (e) {
      // Non-blocking: allow profile editing even if schedule can't be refreshed.
      debugPrint('Failed to refresh working hours: $e');
    }
  }

  Future<void> _loadDoctorData() async {
    try {
      final doctor = await _dbService.ensureCurrentDoctorProfile();

      // مهم: لا تربط تعبئة بيانات الطبيب بنجاح تحميل ساعات العمل.
      // لو جدول doctor_working_hours غير موجود أو سياسات RLS تمنع القراءة،
      // كان ذلك يؤدي إلى صفحة تعديل فارغة بالكامل.
      if (!mounted) return;
      setState(() {
        _fullNameController.text = doctor.fullName;
        _titleController.text = doctor.title ?? '';
        _phoneController.text = doctor.phone;
        _bioController.text = doctor.bio ?? '';
        _servicesController.text = doctor.services ?? '';
        _servicesList = (doctor.services ?? '')
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        _consultationFeeController.text =
            doctor.consultationFee?.toString() ?? '';
        _introVideoUrlController.text = doctor.introVideoUrl ?? '';
        _whatsappController.text = doctor.whatsappNumber ?? '';
        _facebookController.text = doctor.facebookUrl ?? '';
        _qualificationsController.text = doctor.qualifications ?? '';
        _selectedCenter = _parseLocationToCenter(doctor.location);
        _addressController.text = doctor.clinicAddress ?? '';
        _geoLocationController.text = doctor.geoLocation ?? '';
        _workingHoursNotesController.text = doctor.workingHoursNotes ?? '';
        _selectedSpecialization = doctor.specialization;
        _profileImageUrl = doctor.profileImageUrl;
        _galleryImageUrls = List<String>.from(doctor.galleryImageUrls ?? []);
        _newGalleryImages = <File>[];
        _isBookingEnabled = doctor.isBookingEnabled;
        _emergency24Enabled = doctor.emergency24h;
        _homeVisitEnabled = doctor.homeVisit;
        _emergencyPhoneController.text = doctor.emergencyPhone ?? '';
      });

      try {
        final hours = await _dbService.getDoctorWorkingHours(
          doctorId: doctor.id,
        );
        if (!mounted) return;
        setState(() {
          _applyWorkingHoursRows(hours);
        });
      } catch (e) {
        developer.log(
          'Failed to load doctor working hours; continuing without them',
          error: e,
          name: 'DoctorProfileScreen',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
    }
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndCropProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndCropProfileImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCropProfileImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 92);
      if (xfile == null) return;

      // بعض أجهزة أندرويد (خاصة مع Photo Picker) قد تُرجع content://
      // أو مساراً غير موجود؛ ننسخ الملف إلى مسار مؤقت قبل تمريره للقص.
      String sourcePath = xfile.path.trim();
      if (sourcePath.isEmpty) return;

      File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        final bytes = await xfile.readAsBytes();
        final tmpDir = Directory.systemTemp;
        final tmpPath =
            '${tmpDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        sourceFile = File(tmpPath);
        await sourceFile.writeAsBytes(bytes, flush: true);
        sourcePath = sourceFile.path;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'قص الصورة',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'قص الصورة'),
        ],
      );

      // لو المستخدم قفل شاشة القص أو فشلت العملية بدون Exception
      if (cropped == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم قص الصورة (تم الإلغاء أو تعذر فتح أداة القص).'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final path = cropped.path.trim();
      if (path.isEmpty) return;
      final file = File(path);
      if (!await file.exists()) return;

      if (!mounted) return;
      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      debugPrint('Pick/crop image failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح أداة قص الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges(Doctor doctor) async {
    final messenger = ScaffoldMessenger.of(context);

    if ((_selectedCenter ?? '').trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار المدينة / المركز'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_qualificationsController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ المؤهلات والشهادات مطلوبة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_bioController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ السيرة الذاتية مطلوبة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_servicesList.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ يجب إضافة خدمة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ رقم الهاتف مطلوب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_whatsappController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ رقم واتساب مطلوب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ العنوان التفصيلي مطلوب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_emergency24Enabled &&
        _emergencyPhoneController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ رقم الطوارئ مطلوب عند تفعيل طوارئ 24 ساعة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // التحقق من الصورة الشخصية
    if (_selectedImage == null &&
        (_profileImageUrl == null || _profileImageUrl!.trim().isEmpty)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ الصورة الشخصية مطلوبة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // التحقق من جدول العيادة (يجب تفعيل يوم واحد على الأقل)
    bool hasAtLeastOneDay = false;
    for (int i = 0; i < 7; i++) {
      final hasTimes = _dayStart[i] != null && _dayEnd[i] != null;
      if (_dayEnabled[i] || hasTimes) {
        hasAtLeastOneDay = true;
        break;
      }
    }

    if (!hasAtLeastOneDay) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ يجب تحديد يوم واحد على الأقل في جدول العيادة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('جاري الحفظ...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      String? imageUrl = _profileImageUrl;
      final feeText = _consultationFeeController.text.trim();
      double? consultationFee;
      if (feeText.isNotEmpty) {
        consultationFee = double.tryParse(feeText);
        if (consultationFee == null) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('يرجى إدخال قيمة كشف صحيحة (أرقام فقط).'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (_selectedImage != null) {
        try {
          imageUrl = await _dbService.uploadProfileImage(
            doctorId: doctor.id,
            imageFile: _selectedImage!,
          );
        } catch (e) {
          debugPrint('Error uploading profile image: $e');
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text('تحذير: فشل رفع الصورة - $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final mergedGalleryUrls = List<String>.from(_galleryImageUrls);
      for (final file in _newGalleryImages) {
        try {
          final url = await _dbService.uploadGalleryImage(
            doctorId: doctor.id,
            imageFile: file,
          );
          mergedGalleryUrls.add(url);
        } catch (e) {
          debugPrint('Error uploading gallery image: $e');
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text('تحذير: فشل رفع صورة في المعرض - $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final updatedDoctor = await _dbService.updateDoctorProfile(
        doctorId: doctor.id,
        fullName: _fullNameController.text,
        title: _titleController.text,
        phone: _phoneController.text,
        specialization: _selectedSpecialization,
        bio: _bioController.text,
        services: _servicesList.join('\n'),
        consultationFee: consultationFee,
        galleryImageUrls: mergedGalleryUrls,
        introVideoUrl: _introVideoUrlController.text,
        profileImageUrl: imageUrl,
        whatsappNumber: _whatsappController.text,
        facebookUrl: _facebookController.text,
        qualifications: _qualificationsController.text,
        // تم حذف حقل "المنطقة" من الواجهة، نحفظ المركز فقط.
        location: ((_selectedCenter ?? '').trim().isEmpty)
            ? null
            : (_selectedCenter ?? '').trim(),
        clinicAddress: _addressController.text,
        geoLocation: _geoLocationController.text,
        workingHoursNotes: _workingHoursNotesController.text,
        emergency24h: _emergency24Enabled,
        emergencyPhone:
            _emergency24Enabled ? _emergencyPhoneController.text : null,
        homeVisit: _homeVisitEnabled,
        isBookingEnabled: _isBookingEnabled,
      );

      int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
      for (var i = 0; i < 7; i++) {
        if (!_dayEnabled[i]) continue;
        final start = _dayStart[i];
        final end = _dayEnd[i];
        if (start == null || end == null) {
          throw Exception(
            'يرجى تحديد وقت البداية والنهاية لليوم: ${_weekDays[i]}',
          );
        }
        if (toMinutes(end) <= toMinutes(start)) {
          throw Exception(
            'وقت النهاية يجب أن يكون بعد البداية لليوم: ${_weekDays[i]}',
          );
        }
      }

      final workingEntries = List<DoctorWorkingHours>.generate(7, (index) {
        return DoctorWorkingHours(
          doctorId: doctor.id,
          dayOfWeek: index,
          isEnabled: _dayEnabled[index],
          startTime: _dayStart[index],
          endTime: _dayEnd[index],
        );
      });

      await _dbService.upsertDoctorWorkingHours(
        doctorId: doctor.id,
        entries: workingEntries,
      );

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ تم تحديث البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isEditing = false;
        _selectedImage = null;
        _newGalleryImages = <File>[];
        _galleryImageUrls = List<String>.from(
          updatedDoctor.galleryImageUrls ?? [],
        );
        _profileImageUrl = updatedDoctor.profileImageUrl;
        _doctorFuture = _dbService.ensureCurrentDoctorProfile();
        _dataWasUpdated = true; // تحديد أن البيانات تم تحديثها
      });
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _ensureInlinePaymentStateFromDoctor(Doctor doctor) {
    if (_paymentInlineInitialized) return;

    _paymentInlineInitialized = true;
    _inlineUseVodafoneCash = false;
    _inlineUseInstaPay = false;
    _inlineVodafoneCashController.text = '';
    _inlineInstaPayController.text = '';

    final methods = (doctor.paymentMethod ?? '').split(',');
    final accounts = (doctor.paymentAccount ?? '').split(',');

    for (int i = 0; i < methods.length; i++) {
      if (i >= accounts.length) break;
      final method = methods[i];
      final account = accounts[i];
      if (method == 'vodafone_cash' && account.isNotEmpty) {
        _inlineUseVodafoneCash = true;
        _inlineVodafoneCashController.text = account;
      } else if (method == 'instapay' && account.isNotEmpty) {
        _inlineUseInstaPay = true;
        _inlineInstaPayController.text = account;
      }
    }
  }

  Future<void> _saveInlinePaymentSettings(Doctor doctor) async {
    final messenger = ScaffoldMessenger.of(context);

    final vodafoneAccount = _inlineVodafoneCashController.text.trim();
    final instaPayAccount = _inlineInstaPayController.text.trim();

    if (_inlineUseVodafoneCash && vodafoneAccount.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم فودافون كاش.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_inlineUseInstaPay && instaPayAccount.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم/معرّف انستا باي.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final methods = <String>[];
    final accounts = <String>[];

    if (_inlineUseVodafoneCash && vodafoneAccount.isNotEmpty) {
      methods.add('vodafone_cash');
      accounts.add(vodafoneAccount);
    }

    if (_inlineUseInstaPay && instaPayAccount.isNotEmpty) {
      methods.add('instapay');
      accounts.add(instaPayAccount);
    }

    final paymentMethod = methods.isEmpty ? null : methods.join(',');
    final paymentAccount = accounts.isEmpty ? null : accounts.join(',');

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('جاري حفظ طرق الدفع...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      await _dbService.updateDoctorProfile(
        doctorId: doctor.id,
        paymentMethod: paymentMethod,
        paymentAccount: paymentAccount,
      );

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ تم حفظ طرق الدفع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _paymentInlineInitialized = false;
        _doctorFuture = _dbService.ensureCurrentDoctorProfile();
      });
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ طرق الدفع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openGoogleMaps(String? query) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final uri = hasQuery
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query.trim())}',
          )
        : Uri.parse('https://www.google.com/maps');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح خرائط جوجل، حاول مرة أخرى.')),
      );
    }
  }

  ({double lat, double lng})? _tryParseLatLngFromText(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    // 1) Google Maps URLs often contain: @lat,lng
    final atMatch = RegExp(
      r'@\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(t);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1) ?? '');
      final lng = double.tryParse(atMatch.group(2) ?? '');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    // 2) query=lat,lng or q=lat,lng
    final qMatch = RegExp(
      r'(?:query|q)=\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(t);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1) ?? '');
      final lng = double.tryParse(qMatch.group(2) ?? '');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    // 3) Plain "lat,lng"
    final plain = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(t);
    if (plain != null) {
      final lat = double.tryParse(plain.group(1) ?? '');
      final lng = double.tryParse(plain.group(2) ?? '');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    return null;
  }

  Future<void> _pickGeoLocationFromGoogleMaps() async {
    try {
      final clip = await Clipboard.getData('text/plain');
      final text = (clip?.text ?? '').trim();
      final coords = _tryParseLatLngFromText(text);
      if (coords != null) {
        setState(() {
          _geoLocationController.text = '${coords.lat},${coords.lng}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الموقع من الحافظة بنجاح')),
          );
        }
        return;
      }

      final before = _geoLocationController.text.trim();
      await _openGoogleMaps(before.isEmpty ? null : before);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'افتح خرائط Google وحدد الموقع ثم "مشاركة" → "نسخ الرابط/الإحداثيات".\nثم ارجع واضغط زر اختيار الموقع مرة أخرى.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      // If clipboard access fails for any reason, fallback to GPS capture.
      await _captureCurrentLocation();
    }
  }

  Future<void> _captureCurrentLocation() async {
    try {
      // التحقق من تفعيل خدمات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        if (mounted) {
          // عرض خيار الإدخال اليدوي إذا لم تكن خدمات الموقع متوفرة
          _showManualLocationDialog();
        }
        return;
      }

      // التحقق من الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showManualLocationDialog();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showManualLocationDialog();
        }
        return;
      }

      // الحصول على الموقع الحالي
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('جاري تحديد موقعك...')));
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      // حفظ الموقع بصيغة latitude,longitude
      final locationString = '${position.latitude},${position.longitude}';

      if (!mounted) return;
      setState(() {
        _geoLocationController.text = locationString;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التقاط الموقع بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التقاط الموقع: ${e.toString()}'),
            action: SnackBarAction(
              label: 'إدخال يدوي',
              onPressed: () {
                if (!mounted) return;
                _showManualLocationDialog();
              },
            ),
          ),
        );
      }
    }
  }

  void _showManualLocationDialog() {
    if (!mounted) return;
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال الموقع يدوياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يمكنك الحصول على الإحداثيات من خرائط جوجل بالنقر على الموقع',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude (خط العرض)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude (خط الطول)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _dataWasUpdated),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return;
              final lat = latController.text.trim();
              final lng = lngController.text.trim();

              if (lat.isNotEmpty && lng.isNotEmpty) {
                setState(() {
                  _geoLocationController.text = '$lat,$lng';
                });

                // اغلاق الحوار
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context, _dataWasUpdated);
                }

                // استخدم context الخاص بالشاشة (وليس Context الخاص بالحوار)
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ الموقع')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال الإحداثيات كاملة'),
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _servicesController.dispose();
    _newServiceController.dispose();
    _consultationFeeController.dispose();
    _introVideoUrlController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _qualificationsController.dispose();
    _addressController.dispose();
    _geoLocationController.dispose();
    _workingHoursNotesController.dispose();
    _emergencyPhoneController.dispose();
    _inlineVodafoneCashController.dispose();
    _inlineInstaPayController.dispose();
    super.dispose();
  }

  Future<void> _pickGalleryImages() async {
    final images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    setState(() {
      _newGalleryImages.addAll(images.map((x) => File(x.path)));
    });
  }

  void _addService() {
    final service = _newServiceController.text.trim();
    if (service.isEmpty) return;
    setState(() {
      _servicesList.add(service);
      _newServiceController.clear();
    });
  }

  void _removeService(int index) {
    setState(() {
      _servicesList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          backgroundColor: const Color(0xFF246BCE),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorMessagesScreen(),
                  ),
                );
              },
              tooltip: 'الرسائل',
            ),
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  setState(() => _isEditing = false);
                } else {
                  _loadDoctorData();
                  setState(() => _isEditing = true);
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<Doctor?>(
          future: _doctorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'حدث خطأ أثناء تحميل الملف الشخصي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _doctorFuture = _dbService
                                .ensureCurrentDoctorProfile();
                          });
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'لا يوجد سجل للطبيب مرتبط بحسابك بعد.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _doctorFuture = _dbService
                                .ensureCurrentDoctorProfile();
                          });
                        },
                        child: const Text('إنشاء/تحديث السجل تلقائياً'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final doctor = snapshot.data!;

            final content = Column(
              children: [
                // بطاقة الرأس: نفس تصميم بطاقة الطبيب في صفحة التخصص
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DoctorSummaryCard(
                    doctor: doctor,
                    cardColor: const Color(0xFF246BCE),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailScreen(
                            doctor: doctor,
                            cardColor: const Color(0xFF246BCE),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // المحتوى
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    _isEditing ? 16 : 0,
                    16,
                    16,
                  ),
                  child: _isEditing
                      ? _buildEditForm(doctor)
                      : _buildViewMode(doctor),
                ),
                // مسافة إضافية في الأسفل لتجنب تغطية المحتوى بأزرار الحفظ
                SizedBox(height: _isEditing ? 140 : 80),
              ],
            );

            if (!_isEditing) {
              return SingleChildScrollView(child: content);
            }

            return Stack(
              children: [
                SingleChildScrollView(child: content),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildEditStickyActions(doctor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditStickyActions(Doctor doctor) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('إلغاء'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _saveChanges(doctor),
                icon: const Icon(Icons.save),
                label: const Text('حفظ التغييرات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF246BCE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode(Doctor doctor) {
    if (doctor.isPayAtBookingEnabled) {
      _ensureInlinePaymentStateFromDoctor(doctor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // بطاقة سريعة لتعديل الملف الشخصي أسفل بطاقة الرأس مباشرة
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF246BCE), Color(0xFF00BCD4)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF246BCE).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              _loadDoctorData();
              setState(() {
                _isEditing = true;
              });
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل الملف الشخصي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اضغط هنا لتحديث بياناتك وصورتك وخدماتك',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        if (doctor.isPublished) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF246BCE).withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF246BCE).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        color: Color(0xFF246BCE),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'تم نشر صفحتك',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'إذا لم تظهر بطاقتك في صفحة التخصص، استخدم زر التحقق للتأكد أن التطبيق يستطيع جلبك ضمن قائمة التخصص.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isCheckingVisibility
                      ? null
                      : () => _checkVisibilityInSpecialty(doctor),
                  icon: _isCheckingVisibility
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('تحقق من الظهور في التخصص'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF246BCE),
                    side: BorderSide(
                      color: const Color(0xFF246BCE).withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (!doctor.isPublished) ...[
          const SizedBox(height: 24),
        ],
        // قسم الحجز عبر التطبيق
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book_online,
                      color: Color(0xFF00BCD4),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'إعدادات الحجز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الحجز عبر التطبيق',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Switch(
                      value: doctor.isBookingEnabled,
                      onChanged: (value) async {
                        // تحديث حالة الحجز
                        try {
                          await _dbService.updateDoctorProfile(
                            doctorId: doctor.id,
                            isBookingEnabled: value,
                          );

                          if (mounted) {
                            setState(() {
                              _doctorFuture = _dbService
                                  .ensureCurrentDoctorProfile();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '✓ تم تفعيل الحجز عبر التطبيق'
                                      : '✓ تم تعطيل الحجز عبر التطبيق',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ في تحديث الحالة: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      activeThumbColor: const Color(0xFF00BCD4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                doctor.isBookingEnabled
                    ? 'الحجز مفعّل - يمكن للمرضى حجز مواعيد معك'
                    : 'الحجز معطل - لن يتمكن المرضى من حجز مواعيد',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الدفع عند الحجز',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Switch(
                      value: doctor.isPayAtBookingEnabled,
                      onChanged: (value) async {
                        try {
                          await _dbService.updateDoctorProfile(
                            doctorId: doctor.id,
                            isPayAtBookingEnabled: value,
                          );

                          if (mounted) {
                            setState(() {
                              _doctorFuture = _dbService
                                  .ensureCurrentDoctorProfile();
                              _paymentInlineInitialized = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '✓ تم تفعيل الدفع عند الحجز'
                                      : '✓ تم تعطيل الدفع عند الحجز',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ في تحديث الحالة: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      activeThumbColor: const Color(0xFF16A34A),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              if (doctor.isPayAtBookingEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'طرق الدفع المتاحة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _inlineUseVodafoneCash,
                            onChanged: (v) {
                              setState(() {
                                _inlineUseVodafoneCash = v ?? false;
                                if (!_inlineUseVodafoneCash) {
                                  _inlineVodafoneCashController.text = '';
                                }
                              });
                            },
                          ),
                          const Text(
                            'فودافون كاش',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (_inlineUseVodafoneCash) ...[
                        TextField(
                          controller: _inlineVodafoneCashController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم فودافون كاش',
                            hintText: 'مثال: 01XXXXXXXXX',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Checkbox(
                            value: _inlineUseInstaPay,
                            onChanged: (v) {
                              setState(() {
                                _inlineUseInstaPay = v ?? false;
                                if (!_inlineUseInstaPay) {
                                  _inlineInstaPayController.text = '';
                                }
                              });
                            },
                          ),
                          const Text(
                            'انستا باي',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (_inlineUseInstaPay) ...[
                        TextField(
                          controller: _inlineInstaPayController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'معرّف انستا باي',
                            hintText: 'رقم الهاتف أو البريد المرتبط',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => _saveInlinePaymentSettings(doctor),
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ طرق الدفع'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DoctorAppointmentsPanel(dbService: _dbService),
        const SizedBox(height: 24),
        _DoctorQuestionsManagementPanel(
          dbService: _dbService,
          doctorId: doctor.id,
        ),
        const SizedBox(height: 24),
        const Text(
          'يمكنك الانتقال إلى وضع التعديل لتحديث بياناتك متى احتجت ذلك.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _requestAccountDeletion(doctor),
          icon: const Icon(Icons.delete_forever, size: 20),
          label: const Text(
            'طلب حذف الحساب',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سيتم مراجعة طلبك من قبل الإدارة وحذف حسابك خلال 24-48 ساعة',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _handleSignOut,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text(
            'تسجيل الخروج',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: Color(0xFF64748B), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _checkVisibilityInSpecialty(Doctor doctor) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final specialization = doctor.specialization.trim();
    if (specialization.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('لا يمكن التحقق لأن التخصص غير محدد في ملفك.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingVisibility = true;
    });

    try {
      // Refresh doctor row first to ensure we have the latest publish flags.
      final latest = await _dbService.ensureCurrentDoctorProfile();
      final list = await _dbService.getDoctorsBySpecialty(specialization);
      final found = list.any((d) => d.id == latest.id);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            found
                ? '✓ تم العثور على بطاقتك ضمن قائمة "$specialization".'
                : 'لم يتم العثور على بطاقتك ضمن قائمة "$specialization". غالبًا هناك اختلاف في نص التخصص أو أن النشر لم يُفعّل فعليًا في قاعدة البيانات.',
          ),
          backgroundColor: found ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر التحقق: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVisibility = false;
        });
      }
    }
  }

  Future<void> _requestAccountDeletion(Doctor doctor) async {
    if (!mounted) return;

    // التأكيد من المستخدم
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'تأكيد طلب الحذف',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              'هل أنت متأكد من رغبتك في حذف حسابك؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'سيتم مراجعة طلبك من قبل الإدارة وحذف جميع بياناتك بشكل نهائي.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الطلب'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('جاري إرسال الطلب...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      await _dbService.requestAccountDeletion(doctorId: doctor.id);

      if (!mounted) return;
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب حذف الحساب بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // إعادة تحميل البيانات لتحديث الحالة
      setState(() {
        _doctorFuture = _dbService.ensureCurrentDoctorProfile();
      });
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    if (!mounted) return;

    // التأكيد من المستخدم
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246BCE),
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _dbService.signOut();

      if (!mounted) return;

      // الانتقال إلى صفحة تسجيل الدخول
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/doctor_login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تسجيل الخروج: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEditForm(Doctor doctor) {
    const primary = Color(0xFF246BCE);

    InputDecoration deco({String? hintText, IconData? icon}) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      );
    }

    Widget section({
      required String title,
      required IconData icon,
      required Widget child,
      bool initiallyExpanded = true,
      String? subtitle,
      Color? accentColor,
    }) {
      final sectionColor = accentColor ?? primary;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, sectionColor.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sectionColor.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: sectionColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    sectionColor.withValues(alpha: 0.15),
                    sectionColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: sectionColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: sectionColor, size: 22),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
            children: [child],
          ),
        ),
      );
    }

    Widget fieldLabel(String text, {bool required = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      );
    }

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header جمالي + حالة النشر
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.08),
                  const Color(0xFF00BCD4).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primary.withValues(alpha: 0.15),
                            const Color(0xFF00BCD4).withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          Icon(Icons.edit_document, color: primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تعديل الملف الشخصي',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'قم بتحديث بياناتك لتظهر بشكل أفضل للمرضى',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!doctor.isPublished) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color:
                            const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.visibility_off,
                                color: Color(0xFFF59E0B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'صفحتك غير ظاهرة للمرضى بعد',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doctor.publishRequested
                              ? 'تم إرسال طلب النشر للإدارة. ستظهر بطاقتك في صفحة التخصص بعد الموافقة.'
                              : 'لن تظهر بطاقتك في صفحة التخصص حتى يتم إرسال طلب النشر وموافقة الإدارة.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (!doctor.publishRequested)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              try {
                                await _dbService
                                    .requestPublishForCurrentDoctor();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('تم إرسال طلب النشر بنجاح'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {
                                  _doctorFuture = _dbService
                                      .ensureCurrentDoctorProfile();
                                });
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'تعذر إرسال طلب النشر: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send),
                            label: const Text('طلب نشر الصفحة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _doctorFuture = _dbService
                                    .ensureCurrentDoctorProfile();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث الحالة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(
                                  color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          section(
            title: 'الملف الشخصي',
            icon: Icons.person,
            subtitle: 'الصورة والاسم والتخصص (الصورة مطلوبة *)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      // حدود تدرجية حول الصورة
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withValues(alpha: 0.6),
                              const Color(0xFF00BCD4).withValues(alpha: 0.8),
                              primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor: const Color(0xFFF1F5F9),
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                          as ImageProvider
                                    : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                          as ImageProvider
                                    : null,
                                child:
                                    _selectedImage == null &&
                                        _profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Colors.grey[400],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedImage != null || _profileImageUrl != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _profileImageUrl = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                fieldLabel('الاسم الكامل', required: true),
                TextField(
                  controller: _fullNameController,
                  decoration: deco(icon: Icons.badge_outlined),
                ),
                const SizedBox(height: 12),
                fieldLabel('التخصص', required: true),
                DropdownButtonFormField<String>(
                  initialValue:
                      specializations.contains(_selectedSpecialization)
                      ? _selectedSpecialization
                      : null,
                  hint: const Text('اختر التخصص'),
                  items: specializations
                      .map(
                        (spec) =>
                            DropdownMenuItem(value: spec, child: Text(spec)),
                      )
                      .toList(),
                  onChanged: null, // تعطيل التعديل
                  disabledHint: Text(
                    _selectedSpecialization ?? 'غير محدد',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  decoration: deco(
                    icon: Icons.local_hospital_outlined,
                  ).copyWith(filled: true, fillColor: const Color(0xFFF1F5F9)),
                ),
                const SizedBox(height: 12),
                fieldLabel('اللقب', required: true),
                TextField(
                  controller: _titleController,
                  decoration: deco(
                    hintText: 'مثال: استشاري / أخصائي / دكتور',
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          section(
            title: 'عن الطبيب',
            icon: Icons.article_outlined,
            subtitle: 'المؤهلات والسيرة والخدمات',
            initiallyExpanded: true,
            accentColor: const Color(0xFF10B981),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fieldLabel('المؤهلات والشهادات', required: true),
                TextField(
                  controller: _qualificationsController,
                  maxLines: 4,
                  decoration: deco(
                    hintText:
                        'بكالوريوس الطب والجراحة - جامعة القاهرة\nماجستير في التخصص',
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                fieldLabel('السيرة الذاتية', required: true),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: deco(
                    hintText: 'نبذة مختصرة عن الخبرة والتخصصات الدقيقة',
                    icon: Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                fieldLabel('الخدمات المقدمة', required: true),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newServiceController,
                        decoration: deco(
                          hintText: 'أدخل خدمة',
                          icon: Icons.medical_services_outlined,
                        ),
                        onSubmitted: (_) => _addService(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addService,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_servicesList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _servicesList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final service = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  service,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _removeService(index),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                // طوارئ 24 ساعة وزيارة منزلية (كل حقل في صف مستقل)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text(
                      'طوارئ 24 ساعة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    value: _emergency24Enabled,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor:
                      Colors.white.withValues(alpha: 0.2),
                    onChanged: (v) {
                      setState(() {
                        _emergency24Enabled = v;
                        if (!v) {
                          _emergencyPhoneController.clear();
                        }
                      });
                    },
                  ),
                ),
                if (_emergency24Enabled) ...[
                  const SizedBox(height: 12),
                  fieldLabel('رقم طوارئ 24 ساعة', required: true),
                  TextField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: deco(
                      hintText: 'رقم مخصص للطوارئ السريعة',
                      icon: Icons.emergency,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF16A34A).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text(
                      'زيارة منزلية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    value: _homeVisitEnabled,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor:
                      Colors.white.withValues(alpha: 0.2),
                    onChanged: (v) {
                      setState(() {
                        _homeVisitEnabled = v;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          section(
            title: 'التواصل',
            icon: Icons.call_outlined,
            subtitle: 'الهاتف وواتساب وفيسبوك',
            initiallyExpanded: false,
            accentColor: const Color(0xFF8B5CF6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          fieldLabel('رقم الهاتف', required: true),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: deco(icon: Icons.phone_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          fieldLabel('رقم واتساب', required: true),
                          TextField(
                            controller: _whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: deco(
                              hintText: 'رقم واتساب',
                              icon: Icons.chat_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                fieldLabel('رابط صفحة الفيس بوك'),
                TextField(
                  controller: _facebookController,
                  decoration: deco(
                    hintText: 'https://www.facebook.com/yourpage',
                    icon: Icons.public_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          section(
            title: 'العيادة',
            icon: Icons.location_on_outlined,
            subtitle: 'العنوان والموقع على الخريطة',
            initiallyExpanded: false,
            accentColor: const Color(0xFFEC4899),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fieldLabel('المدينة / المركز', required: true),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('center_${_selectedCenter ?? ''}'),
                  isExpanded: true,
                  initialValue:
                      (_selectedCenter != null &&
                          fayoumCenters.contains(_selectedCenter))
                      ? _selectedCenter
                      : null,
                  items: fayoumCenters
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(
                            c,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _selectedCenter = value;
                    });
                  },
                  decoration: deco(
                    hintText: 'اختر المركز',
                    icon: Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                fieldLabel('العنوان التفصيلي', required: true),
                TextField(
                  controller: _addressController,
                  decoration: deco(
                    hintText: 'مثال: شارع الحرية، برج السلام، الدور الثاني',
                    icon: Icons.home_work_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الموقع الجغرافي',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (_geoLocationController.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            _openGoogleMaps(_geoLocationController.text),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('عرض'),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _geoLocationController.text.isEmpty
                              ? 'اضغط لاختيار موقع العيادة من خرائط Google'
                              : _geoLocationController.text,
                          style: TextStyle(
                            color: _geoLocationController.text.isEmpty
                                ? Colors.grey
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickGeoLocationFromGoogleMaps,
                        icon: const Icon(Icons.my_location),
                        label: const Text('اختيار'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          section(
            title: 'الحجز والمواعيد',
            icon: Icons.calendar_month_outlined,
            subtitle: 'قيمة الكشف وجدول العيادة (جدول العيادة مطلوب *)',
            initiallyExpanded: false,
            accentColor: const Color(0xFFF59E0B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fieldLabel('قيمة الكشف'),
                TextField(
                  controller: _consultationFeeController,
                  keyboardType: TextInputType.number,
                  decoration: deco(
                    hintText: 'مثال: 200',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkingHoursScheduleScreen(doctor: doctor),
                      ),
                    );
                    if (result == true) {
                      await _refreshWorkingHoursAndNotes(doctorId: doctor.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.schedule, color: primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'جدول العيادة',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'تحديد مواعيد العمل لكل يوم',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),

          section(
            title: 'الوسائط',
            icon: Icons.perm_media_outlined,
            subtitle: 'معرض الصور والفيديو التعريفي',
            initiallyExpanded: false,
            accentColor: const Color(0xFF6366F1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'معرض الصور',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickGalleryImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('إضافة'),
                    ),
                  ],
                ),
                if (_galleryImageUrls.isNotEmpty ||
                    _newGalleryImages.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _galleryImageUrls.length + _newGalleryImages.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isExisting = index < _galleryImageUrls.length;
                        final child = isExisting
                            ? Image.network(
                                _galleryImageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                              )
                            : Image.file(
                                _newGalleryImages[index -
                                    _galleryImageUrls.length],
                                fit: BoxFit.cover,
                              );

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 96,
                                height: 96,
                                color: Colors.white,
                                child: child,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isExisting) {
                                      _galleryImageUrls.removeAt(index);
                                    } else {
                                      _newGalleryImages.removeAt(
                                        index - _galleryImageUrls.length,
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  Text(
                    'لا توجد صور بعد',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                const SizedBox(height: 12),
                fieldLabel('فيديو تعريفي (اختياري)'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _introVideoUrlController,
                        decoration: deco(
                          hintText: 'ضع رابط الفيديو',
                          icon: Icons.video_library_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'رفع فيديو من المعرض (≤ 30MB)',
                      onPressed: _isUploadingIntroVideo
                          ? null
                          : () => _pickAndUploadIntroVideo(doctor),
                      icon: _isUploadingIntroVideo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                    ),
                    IconButton(
                      tooltip: 'تشغيل',
                      onPressed: _introVideoUrlController.text.trim().isEmpty
                          ? null
                          : () => _previewIntroVideo(
                              _introVideoUrlController.text,
                            ),
                      icon: const Icon(Icons.play_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed:
                          (_isUploadingIntroVideo ||
                              _introVideoUrlController.text.trim().isEmpty)
                          ? null
                          : () => _clearIntroVideo(doctor),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorAppointmentsPanel extends StatefulWidget {
  final DoctorDatabaseService dbService;

  const _DoctorAppointmentsPanel({required this.dbService});

  @override
  State<_DoctorAppointmentsPanel> createState() =>
      _DoctorAppointmentsPanelState();
}

class _DoctorAppointmentsPanelState extends State<_DoctorAppointmentsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _pending = const [];
  List<Map<String, dynamic>> _accepted = const [];
  List<Map<String, dynamic>> _rejected = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final doctor = await widget.dbService.ensureCurrentDoctorProfile();
      final doctorId = doctor.id;

      final pending = await widget.dbService.getAppointmentsForDoctor(
        doctorId: doctorId,
        status: DoctorDatabaseService.appointmentStatusPending,
      );
      final accepted = await widget.dbService.getAppointmentsForDoctor(
        doctorId: doctorId,
        status: DoctorDatabaseService.appointmentStatusAccepted,
      );
      final rejected = await widget.dbService.getAppointmentsForDoctor(
        doctorId: doctorId,
        status: DoctorDatabaseService.appointmentStatusRejected,
      );

      if (!mounted) return;
      setState(() {
        _pending = pending;
        _accepted = accepted;
        _rejected = rejected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المواعيد: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus({
    required Map<String, dynamic> appointment,
    required String status,
  }) async {
    final appointmentId =
        appointment['id'] ??
        appointment['appointment_id'] ??
        appointment['appointmentId'];
    if (appointmentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('معرّف الموعد غير صالح'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // خيارات الطبيب حسب نوع الإجراء
    String? responseMessage;
    DateTime? suggestedDate;
    String? suggestedTime;

    if (status == DoctorDatabaseService.appointmentStatusAccepted) {
      final result = await _showAcceptOptionsDialog(appointment);
      if (result == null || !mounted) return;
      responseMessage = result.message;
      suggestedTime = result.suggestedTime;
    } else if (status == DoctorDatabaseService.appointmentStatusRejected) {
      final result = await _showBookingFullOptionsDialog(appointment);
      if (result == null || !mounted) return;
      responseMessage = result.message;
      suggestedDate = result.suggestedDate;
      suggestedTime = result.suggestedTime;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.dbService.updateAppointmentWithDoctorResponse(
        appointmentId: appointmentId,
        status: status,
        responseMessage: responseMessage,
        suggestedDate: suggestedDate,
        suggestedTime: suggestedTime,
      );

      if (!mounted) return;

      // Refresh the appointments list
      await _fetchAppointments();

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == DoctorDatabaseService.appointmentStatusAccepted
                ? 'تم قبول الطلب بنجاح'
                : 'تم تسجيل الحجز كمكتمل',
          ),
          backgroundColor:
              status == DoctorDatabaseService.appointmentStatusAccepted
              ? Colors.green
              : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<_AcceptDialogResult?> _showAcceptOptionsDialog(
    Map<String, dynamic> appointment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final appointmentId =
        appointment['id'] ??
        appointment['appointment_id'] ??
        appointment['appointmentId'];
    if (appointmentId == null) {
      if (!mounted) return null;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح نافذة القبول: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    final messageController = TextEditingController();
    TimeOfDay? suggestedTime;
    String? suggestedTimeStr;

    bool? confirmed;
    var message = '';
    try {
      confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('قبول'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اقتراح ساعة معينة (في نفس اليوم):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: dialogContext,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setDialogState(() {
                                suggestedTime = time;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            suggestedTime != null
                                ? '${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}'
                                : 'اختر الوقت',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات للمريض (اختياري)',
                            hintText:
                                'مثال: يرجى الحضور قبل الموعد بـ 10 دقائق',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('قبول'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return null;
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فتح نافذة القبول: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      message = messageController.text.trim();
      messageController.dispose();
    }

    if (confirmed != true) return null;

    if (suggestedTime != null) {
      suggestedTimeStr =
          '${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}:00';
    }

    return _AcceptDialogResult(
      message: message.isNotEmpty ? message : null,
      suggestedTime: suggestedTimeStr,
    );
  }

  Future<_RejectDialogResult?> _showBookingFullOptionsDialog(
    Map<String, dynamic> appointment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final appointmentId =
        appointment['id'] ??
        appointment['appointment_id'] ??
        appointment['appointmentId'];
    if (appointmentId == null) {
      if (!mounted) return null;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح نافذة الحجز مكتمل: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    final messageController = TextEditingController();
    DateTime? suggestedDate;
    TimeOfDay? suggestedTime;
    var message = '';

    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('الحجز مكتمل'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('يمكنك كتابة ملاحظات واقتراح موعد بديل:'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات للمريض (اختياري)',
                            hintText:
                                'مثال: الحجز مكتمل لهذا اليوم، نقترح الموعد التالي',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'اقتراح موعد بديل (اختياري):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    builder: (context, child) {
                                      return Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      suggestedDate = date;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  suggestedDate != null
                                      ? _formatDate(suggestedDate)
                                      : 'اختر التاريخ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: suggestedDate == null
                                    ? null
                                    : () async {
                                        final time = await showTimePicker(
                                          context: dialogContext,
                                          initialTime: TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (time != null) {
                                          setDialogState(() {
                                            suggestedTime = time;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  suggestedTime != null
                                      ? '${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'الوقت',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (suggestedDate != null && suggestedTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'الموعد البديل: ${_formatDate(suggestedDate)} - ${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return null;
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فتح نافذة الحجز مكتمل: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      message = messageController.text.trim();
      messageController.dispose();
    }

    if (confirmed != true) return null;

    String? suggestedTimeStr;
    if (suggestedTime != null) {
      suggestedTimeStr =
          '${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}:00';
    }

    return _RejectDialogResult(
      message: message.isNotEmpty ? message : null,
      suggestedDate: suggestedDate,
      suggestedTime: suggestedTimeStr,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';
    final raw = value.toString();
    if (!raw.contains(':')) return raw;
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hh = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildTable(
    List<Map<String, dynamic>> items, {
    required bool isPending,
    required String emptyLabel,
    String statusLabel = 'قيد المراجعة',
    Color statusColor = Colors.orange,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPending ? Icons.event_available : Icons.event_note,
                size: 48,
                color: const Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 12),
              Text(
                emptyLabel,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final appointment = items[index];
        final date = _parseDate(appointment['appointment_date']);
        final time = appointment['appointment_time'];
        final patientName = (appointment['patient_name'] ?? '')
            .toString()
            .trim();
        final patientPhone = (appointment['patient_phone'] ?? '')
            .toString()
            .trim();
        final notes = (appointment['notes'] ?? '').toString().trim();
        final paymentReceiptUrl = (appointment['payment_receipt_url'] ?? '')
            .toString()
            .trim();
        final hasPaymentReceipt = paymentReceiptUrl.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.20),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName.isEmpty ? 'مريض' : patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 12,
                              color: const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                patientPhone.isEmpty ? '-' : patientPhone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(time),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: const Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notes,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _updateStatus(
                                appointment: appointment,
                                status: DoctorDatabaseService
                                    .appointmentStatusAccepted,
                              ),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text(
                          'قبول',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _updateStatus(
                                appointment: appointment,
                                status: DoctorDatabaseService
                                    .appointmentStatusRejected,
                              ),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text(
                          'الحجز مكتمل',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // عرض حالة الدفع للطلبات المقبولة
              if (!isPending && statusLabel == 'مقبول') ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasPaymentReceipt
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasPaymentReceipt
                          ? const Color(0xFF10B981)
                          : const Color(0xFFFBBF24),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: hasPaymentReceipt
                              ? const Color(0xFF10B981)
                              : const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasPaymentReceipt
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasPaymentReceipt
                              ? (appointment['payment_confirmed'] == true
                                    ? 'تم تأكيد الدفع ✓'
                                    : 'تم الدفع - إيصال مرفوع')
                              : 'في انتظار رفع إيصال الدفع',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: appointment['payment_confirmed'] == true
                                ? const Color(0xFF15803D)
                                : (hasPaymentReceipt
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF92400E)),
                          ),
                        ),
                      ),
                      if (hasPaymentReceipt) ...[
                        InkWell(
                          onTap: () =>
                              _showReceiptImage(paymentReceiptUrl, appointment),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 18,
                                  color: const Color(0xFF047857),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'عرض',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showReceiptImage(String receiptUrl, Map<String, dynamic> appointment) {
    if (receiptUrl.isEmpty || !mounted) return;

    final bool isPaymentConfirmed = appointment['payment_confirmed'] == true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // صورة الإيصال
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      receiptUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'تعذر تحميل الإيصال',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // زر تأكيد الدفع
              if (!isPaymentConfirmed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _confirmPayment(appointment);
                    },
                    icon: const Icon(Icons.verified),
                    label: const Text('تأكيد الدفع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmPayment(Map<String, dynamic> appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الدفع'),
            content: const Text(
              'هل أنت متأكد من تأكيد استلام الدفع لهذا الموعد؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                ),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.dbService.confirmPayment(appointmentId: appointment['id']);

      if (!mounted) return;

      _fetchAppointments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد الدفع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'طلبات الحجز',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'تحديث',
                  onPressed: _loading ? null : _fetchAppointments,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'تابع جميع طلبات الحجز الواردة وقم بالتصرف مباشرة من هنا.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF246BCE),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF246BCE),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'قيد المراجعة (${_pending.length})'),
                Tab(text: 'مقبولة (${_accepted.length})'),
                Tab(text: 'مرفوضة (${_rejected.length})'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTable(
                    _pending,
                    isPending: true,
                    emptyLabel: 'لا توجد طلبات جديدة حالياً.',
                  ),
                  _buildTable(
                    _accepted,
                    isPending: false,
                    emptyLabel: 'لا توجد طلبات مقبولة بعد.',
                    statusLabel: 'مقبول',
                    statusColor: Colors.green,
                  ),
                  _buildTable(
                    _rejected,
                    isPending: false,
                    emptyLabel: 'لا توجد طلبات مرفوضة.',
                    statusLabel: 'مرفوض',
                    statusColor: Colors.red,
                  ),
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DoctorAppointmentsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح شاشة قائمة الحجز'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptDialogResult {
  final String? message;
  final String? suggestedTime;

  const _AcceptDialogResult({
    required this.message,
    required this.suggestedTime,
  });
}

class _RejectDialogResult {
  final String? message;
  final DateTime? suggestedDate;
  final String? suggestedTime;

  const _RejectDialogResult({
    required this.message,
    required this.suggestedDate,
    required this.suggestedTime,
  });
}

// ============ Questions Management Panel ============
class _DoctorQuestionsManagementPanel extends StatefulWidget {
  final DoctorDatabaseService dbService;
  final String doctorId;

  const _DoctorQuestionsManagementPanel({
    required this.dbService,
    required this.doctorId,
  });

  @override
  State<_DoctorQuestionsManagementPanel> createState() =>
      _DoctorQuestionsManagementPanelState();
}

class _DoctorQuestionsManagementPanelState
    extends State<_DoctorQuestionsManagementPanel> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    if (!mounted) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final questions = await widget.dbService.getDoctorAllQuestions(
        doctorId: widget.doctorId,
      );

      if (!mounted) return;

      if (mounted) {
        setState(() {
          _questions = questions;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _answerQuestion(Map<String, dynamic> question) async {
    final answer = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AnswerQuestionDialog(
          questionText: question['question']?.toString() ?? '',
          initialAnswer: question['answer']?.toString() ?? '',
        );
      },
    );

    // التحقق من القيمة المُرجعة
    if (answer == null || answer.isEmpty) return;
    if (!mounted) return;

    // حفظ الإجابة
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      await widget.dbService.answerQuestion(
        questionId: question['id'],
        answer: answer,
      );

      if (!mounted) return;

      await _fetchQuestions();

      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإجابة بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'خطأ في حفظ الإجابة';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف هذا السؤال؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      await widget.dbService.deleteQuestion(questionId: question['id']);
      await _fetchQuestions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف السؤال'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unanswered = _questions
        .where((q) => q['is_answered'] == false)
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'الأسئلة والاستفسارات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (unanswered > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unanswered جديد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'تحديث',
                  onPressed: _loading ? null : _fetchQuestions,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'أجب على أسئلة المرضى. الأسئلة المُجاب عليها تظهر في صفحتك العامة.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_questions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.question_answer_outlined,
                        size: 48,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد أسئلة بعد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return _buildQuestionItem(q);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(Map<String, dynamic> question) {
    final isAnswered = question['is_answered'] == true;
    final patientName = question['patient_name']?.toString() ?? '';
    final questionText = question['question']?.toString() ?? '';
    final answer = question['answer']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAnswered ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswered ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAnswered ? Icons.check_circle : Icons.help_outline,
                color: isAnswered
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _answerQuestion(question),
                tooltip: isAnswered ? 'تعديل الإجابة' : 'إضافة إجابة',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                onPressed: () => _deleteQuestion(question),
                tooltip: 'حذف',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            questionText,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          if (isAnswered && answer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'إجابتك: $answer',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============ Answer Question Dialog ============
class _AnswerQuestionDialog extends StatefulWidget {
  final String questionText;
  final String initialAnswer;

  const _AnswerQuestionDialog({
    required this.questionText,
    required this.initialAnswer,
  });

  @override
  State<_AnswerQuestionDialog> createState() => _AnswerQuestionDialogState();
}

class _AnswerQuestionDialogState extends State<_AnswerQuestionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAnswer);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('الإجابة على السؤال'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.questionText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'إجابتك',
                  border: OutlineInputBorder(),
                  hintText: 'اكتب إجابتك هنا...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246BCE),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
