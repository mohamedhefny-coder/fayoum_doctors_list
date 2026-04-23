import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/gym_media_service.dart';
import '../services/gym_service.dart';

class AddGymScreen extends StatefulWidget {
  const AddGymScreen({super.key});

  @override
  State<AddGymScreen> createState() => _AddGymScreenState();
}

class _AddGymScreenState extends State<AddGymScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _geoLocationController = TextEditingController();
  final _facebookController = TextEditingController();
  final _priceController = TextEditingController();
  final _offersController = TextEditingController();
  final _discountsController = TextEditingController();
  final _notesController = TextEditingController();

  final _gymService = GymService();
  final _mediaService = GymMediaService();
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  XFile? _coverImageFile;
  Uint8List? _coverImageBytes;

  final List<XFile> _galleryImageFiles = <XFile>[];
  final List<Uint8List> _galleryImageBytes = <Uint8List>[];

  final Set<String> _selectedFeatures = <String>{};

  final Set<String> _selectedGymTypes = <String>{};
  bool _is24Hours = false;
  bool _hasParking = false;

  static const _gymTypes = <String>['رجالي', 'سيدات', 'مختلط'];

  static const _weekDays = <String>[
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  final Map<String, _DaySchedule> _weeklySchedule = {
    for (final d in _weekDays) d: _DaySchedule.empty(),
  };

  static const _featureOptions = <String>[
    'كارديو',
    'أوزان',
    'كروس فيت',
    'تدريب جماعي',
    'مدربين',
    'مدربات',
    'قسم سيدات',
    'قسم رجالي',
    'ساونا',
    'جاكوزي',
    'حمام سباحة',
    'تغذية',
    'بار بروتين',
    'تكييف',
    'واي فاي',
    'دُش',
    'خزائن',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _geoLocationController.dispose();
    _facebookController.dispose();
    _priceController.dispose();
    _offersController.dispose();
    _discountsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _completion {
    int done = 0;
    const total = 7;

    if (_nameController.text.trim().isNotEmpty) done++;
    if (_addressController.text.trim().isNotEmpty) done++;
    if (_phoneController.text.trim().isNotEmpty) done++;
    if (_selectedGymTypes.isNotEmpty) done++;
    if (_is24Hours || _hasAnyWeeklyHours) done++;
    if (_selectedFeatures.isNotEmpty) done++;

    if (_coverImageBytes != null || _galleryImageBytes.isNotEmpty) done++;

    return done / total;
  }

  bool get _hasAnyWeeklyHours {
    for (final d in _weekDays) {
      final s = _weeklySchedule[d];
      if (s == null) continue;
      if (s.men.enabled || s.women.enabled) return true;
    }
    return false;
  }

  Future<void> _pickCoverImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _coverImageFile = picked;
      _coverImageBytes = bytes;
    });
  }

  Future<void> _pickGalleryImages() async {
    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked.isEmpty) return;

    final bytes = <Uint8List>[];
    for (final f in picked) {
      bytes.add(await f.readAsBytes());
    }

    if (!mounted) return;
    setState(() {
      _galleryImageFiles.addAll(picked);
      _galleryImageBytes.addAll(bytes);
    });
  }

  void _removeGalleryImageAt(int index) {
    setState(() {
      _galleryImageFiles.removeAt(index);
      _galleryImageBytes.removeAt(index);
    });
  }

  Map<String, dynamic> _weeklyScheduleToJson() {
    return {
      for (final day in _weekDays)
        day: (_weeklySchedule[day] ?? _DaySchedule.empty()).toJson(),
    };
  }

  bool _validateWeeklySchedule() {
    if (_is24Hours) return true;

    bool hasAny = false;
    for (final day in _weekDays) {
      final s = _weeklySchedule[day] ?? _DaySchedule.empty();
      if (s.men.enabled) {
        hasAny = true;
        if (s.men.from == null || s.men.to == null) return false;
      }
      if (s.women.enabled) {
        hasAny = true;
        if (s.women.from == null || s.women.to == null) return false;
      }
    }

    return hasAny;
  }

  void _toggleFeature(String feature) {
    setState(() {
      if (_selectedFeatures.contains(feature)) {
        _selectedFeatures.remove(feature);
      } else {
        _selectedFeatures.add(feature);
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGymTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر نوع الجيم (يمكن اختيار أكثر من نوع)'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_validateWeeklySchedule()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'من فضلك أكمل جدول أوقات العمل (على الأقل يوم واحد)، وحدد وقت البداية والنهاية للرجال/النساء',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final phone = _phoneController.text.trim();
      final whatsapp = _whatsappController.text.trim();
      final geoLocation = _geoLocationController.text.trim();
      final facebookUrl = _facebookController.text.trim();
      final priceLevel = _priceController.text.trim();
      final offers = _offersController.text.trim();
      final discounts = _discountsController.text.trim();
      final notes = _notesController.text.trim();

      String? coverUrl;
      if (_coverImageFile != null) {
        coverUrl = await _mediaService.uploadImage(_coverImageFile!, 'cover');
      }

      final galleryUrls = <String>[];
      for (final img in _galleryImageFiles) {
        galleryUrls.add(await _mediaService.uploadImage(img, 'gallery'));
      }

      final workingHours = _weeklyScheduleToJson();

      await _gymService.upsertGymData(
        name: name,
        address: address.isEmpty ? null : address,
        phone: phone.isEmpty ? null : phone,
        whatsapp: whatsapp.isEmpty ? null : whatsapp,
        geoLocation: geoLocation.isEmpty ? null : geoLocation,
        facebookUrl: facebookUrl.isEmpty ? null : facebookUrl,
        gymTypes: _selectedGymTypes.toList(),
        features: _selectedFeatures.toList(),
        is24Hours: _is24Hours,
        hasParking: _hasParking,
        priceLevel: priceLevel.isEmpty ? null : priceLevel,
        offers: offers.isEmpty ? null : offers,
        discounts: discounts.isEmpty ? null : discounts,
        notes: notes.isEmpty ? null : notes,
        coverImageUrl: coverUrl,
        galleryImageUrls: galleryUrls,
        workingHours: workingHours,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بيانات الجيم بنجاح'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ بيانات الجيم: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF16A34A)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.8),
      ),
    );
  }

  Widget _cardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF22C55E).withValues(alpha: 0.18),
                        const Color(0xFF16A34A).withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF16A34A)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completion = _completion;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF22C55E).withValues(alpha: 0.06),
                const Color(0xFFF8FAFC),
                const Color(0xFF16A34A).withValues(alpha: 0.05),
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 210,
                backgroundColor: const Color(0xFF16A34A),
                elevation: 0,
                leading: IconButton(
                  tooltip: 'رجوع',
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text(
                        'حفظ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    end: 16,
                    bottom: 14,
                  ),
                  title: const Text(
                    'إضافة صالة رياضية',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              const Color(0xFF22C55E),
                              const Color(0xFF16A34A),
                              const Color(0xFF15803D).withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -24,
                        top: 40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Center(
                        child: Opacity(
                          opacity: 0.20,
                          child: Image.asset(
                            'assets/images/gym.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: 0.18),
                                    const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.10),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'نسبة اكتمال البيانات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: completion,
                                      backgroundColor: const Color(
                                        0xFF16A34A,
                                      ).withValues(alpha: 0.10),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF16A34A),
                                          ),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(completion * 100).round()}% مكتمل',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Form(
                        key: _formKey,
                        onChanged: () => setState(() {}),
                        child: Column(
                          children: [
                            _cardSection(
                              title: 'صور الجيم',
                              icon: Icons.photo_library_rounded,
                              child: _GymMediaSection(
                                coverBytes: _coverImageBytes,
                                galleryBytes: _galleryImageBytes,
                                onPickCover: _isSubmitting
                                    ? null
                                    : _pickCoverImage,
                                onPickGallery: _isSubmitting
                                    ? null
                                    : _pickGalleryImages,
                                onRemoveGalleryAt: _isSubmitting
                                    ? null
                                    : _removeGalleryImageAt,
                              ),
                            ),
                            _cardSection(
                              title: 'معلومات أساسية',
                              icon: Icons.badge_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'اسم الجيم *',
                                      hint: 'مثال: Power House',
                                      icon: Icons.fitness_center,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'من فضلك أدخل اسم الجيم';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _GymTypesSection(
                                    types: _gymTypes,
                                    selectedTypes: _selectedGymTypes,
                                    onChanged: (next) {
                                      setState(() {
                                        _selectedGymTypes
                                          ..clear()
                                          ..addAll(next);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            _cardSection(
                              title: 'الموقع والتواصل',
                              icon: Icons.location_on_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _addressController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'العنوان *',
                                      hint: 'مثال: الفيوم - شارع الجامعة',
                                      icon: Icons.place_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'من فضلك أدخل العنوان';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'رقم الهاتف *',
                                      hint: 'مثال: 01000000000',
                                      icon: Icons.phone_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'من فضلك أدخل رقم الهاتف';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _whatsappController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'رقم الواتساب (اختياري)',
                                      hint: 'مثال: 01000000000',
                                      icon: Icons.chat_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _geoLocationController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'الموقع الجغرافي (اختياري)',
                                      hint: 'مثال: 29.3084, 30.8428',
                                      icon: Icons.my_location_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _facebookController,
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'رابط صفحة فيسبوك (اختياري)',
                                      hint: 'https://facebook.com/...',
                                      icon: Icons.facebook,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _cardSection(
                              title: 'مواعيد العمل والاشتراكات',
                              icon: Icons.schedule_rounded,
                              child: Column(
                                children: [
                                  _WeeklyHoursTable(
                                    days: _weekDays,
                                    schedule: _weeklySchedule,
                                    is24Hours: _is24Hours,
                                    onPickTime: _isSubmitting
                                        ? null
                                        : (day, gender, isFrom) async {
                                            final initial =
                                                _weeklySchedule[day]
                                                    ?.get(gender)
                                                    .getTime(isFrom) ??
                                                const TimeOfDay(
                                                  hour: 10,
                                                  minute: 0,
                                                );
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: initial,
                                            );
                                            if (picked == null) return;
                                            setState(() {
                                              _weeklySchedule[day]
                                                  ?.get(gender)
                                                  .setTime(isFrom, picked);
                                            });
                                          },
                                    onToggleGender: _isSubmitting
                                        ? null
                                        : (day, gender, enabled) {
                                            setState(() {
                                              final g = _weeklySchedule[day]
                                                  ?.get(gender);
                                              if (g == null) return;
                                              g.enabled = enabled;
                                              if (!enabled) {
                                                g.from = null;
                                                g.to = null;
                                              }
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('يعمل 24 ساعة'),
                                          value: _is24Hours,
                                          onChanged: (v) => setState(() {
                                            _is24Hours = v;

                                            if (v) {
                                              for (final day in _weekDays) {
                                                final s = _weeklySchedule[day];
                                                if (s == null) continue;
                                                s.men
                                                  ..enabled = true
                                                  ..from = const TimeOfDay(
                                                    hour: 0,
                                                    minute: 0,
                                                  )
                                                  ..to = const TimeOfDay(
                                                    hour: 23,
                                                    minute: 59,
                                                  );
                                                s.women
                                                  ..enabled = true
                                                  ..from = const TimeOfDay(
                                                    hour: 0,
                                                    minute: 0,
                                                  )
                                                  ..to = const TimeOfDay(
                                                    hour: 23,
                                                    minute: 59,
                                                  );
                                              }
                                            }
                                          }),
                                          activeThumbColor: const Color(
                                            0xFF16A34A,
                                          ),
                                          activeTrackColor: const Color(
                                            0xFF16A34A,
                                          ).withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _priceController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'مستوى الأسعار (اختياري)',
                                      hint: 'مثال: اشتراك شهري 300 جنيه',
                                      icon: Icons.payments_rounded,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            _cardSection(
                              title: 'الخصومات والعروض',
                              icon: Icons.local_offer_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _discountsController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'الخصومات (اختياري)',
                                      hint: 'مثال: خصم 20% للطلاب',
                                      icon: Icons.discount_rounded,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _offersController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'العروض (اختياري)',
                                      hint: 'مثال: اشتراك 3 شهور + شهر مجاني',
                                      icon: Icons.card_giftcard_rounded,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            _cardSection(
                              title: 'الخدمات والمميزات',
                              icon: Icons.auto_awesome_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'اختر المميزات المتوفرة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _featureOptions.map((f) {
                                      final isSelected = _selectedFeatures
                                          .contains(f);
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        onTap: () => _toggleFeature(f),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 160,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(
                                                    0xFF16A34A,
                                                  ).withValues(alpha: 0.12)
                                                : const Color(
                                                    0xFF0F172A,
                                                  ).withValues(alpha: 0.04),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(
                                                      0xFF16A34A,
                                                    ).withValues(alpha: 0.35)
                                                  : Colors.black.withValues(
                                                      alpha: 0.08,
                                                    ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                size: 16,
                                                color: isSelected
                                                    ? const Color(0xFF16A34A)
                                                    : Colors.black45,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                f,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? const Color(0xFF166534)
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('يتوفر موقف سيارات'),
                                    value: _hasParking,
                                    onChanged: (v) => setState(() {
                                      _hasParking = v;
                                    }),
                                    activeThumbColor: const Color(0xFF16A34A),
                                    activeTrackColor: const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.35),
                                  ),
                                ],
                              ),
                            ),
                            _cardSection(
                              title: 'ملاحظات إضافية',
                              icon: Icons.notes_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _notesController,
                                    decoration: _inputDecoration(
                                      label: 'ملاحظات (اختياري)',
                                      hint:
                                          'مثال: يوجد خصم للطلاب / عروض موسمية ...',
                                      icon: Icons.info_outline_rounded,
                                    ),
                                    maxLines: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'حفظ بيانات الجيم',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GymGender { men, women }

class _GenderHours {
  _GenderHours({required this.enabled});

  bool enabled;
  TimeOfDay? from;
  TimeOfDay? to;

  TimeOfDay? getTime(bool isFrom) => isFrom ? from : to;

  void setTime(bool isFrom, TimeOfDay v) {
    if (isFrom) {
      from = v;
    } else {
      to = v;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'from': from == null ? null : _formatTime(from!),
      'to': to == null ? null : _formatTime(to!),
    };
  }

  static String _formatTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _DaySchedule {
  _DaySchedule({required this.men, required this.women});

  final _GenderHours men;
  final _GenderHours women;

  static _DaySchedule empty() {
    return _DaySchedule(
      men: _GenderHours(enabled: false),
      women: _GenderHours(enabled: false),
    );
  }

  _GenderHours get(_GymGender gender) {
    return gender == _GymGender.men ? men : women;
  }

  Map<String, dynamic> toJson() {
    return {'men': men.toJson(), 'women': women.toJson()};
  }
}

class _GymMediaSection extends StatelessWidget {
  const _GymMediaSection({
    required this.coverBytes,
    required this.galleryBytes,
    required this.onPickCover,
    required this.onPickGallery,
    required this.onRemoveGalleryAt,
  });

  final Uint8List? coverBytes;
  final List<Uint8List> galleryBytes;
  final VoidCallback? onPickCover;
  final VoidCallback? onPickGallery;
  final void Function(int index)? onRemoveGalleryAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCover,
                icon: const Icon(Icons.image_outlined),
                label: const Text('اختيار الكفر'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('اختيار صور المعرض'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (coverBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(coverBytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (galleryBytes.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: galleryBytes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        galleryBytes[index],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: onRemoveGalleryAt == null
                            ? null
                            : () => onRemoveGalleryAt!(index),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(34, 34),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _GymTypesSection extends StatelessWidget {
  const _GymTypesSection({
    required this.types,
    required this.selectedTypes,
    required this.onChanged,
  });

  final List<String> types;
  final Set<String> selectedTypes;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedTypes.length == types.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نوع الجيم * (يمكن اختيار أكثر من نوع)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilterChip(
                label: const Text('كل الأنواع'),
                selected: allSelected,
                onSelected: (v) {
                  final next = <String>{};
                  if (v) {
                    next.addAll(types);
                  }
                  onChanged(next);
                },
              ),
              ...types.map((t) {
                final selected = selectedTypes.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (v) {
                    final next = <String>{...selectedTypes};
                    if (v) {
                      next.add(t);
                    } else {
                      next.remove(t);
                    }
                    onChanged(next);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedTypes.isEmpty
                ? 'اختر نوع واحد على الأقل'
                : allSelected
                ? 'تم اختيار: كل الأنواع'
                : 'تم اختيار: ${selectedTypes.length} نوع',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _PickTimeCallback =
    Future<void> Function(String day, _GymGender gender, bool isFrom);

typedef _ToggleGenderCallback =
    void Function(String day, _GymGender gender, bool enabled);

class _WeeklyHoursTable extends StatelessWidget {
  const _WeeklyHoursTable({
    required this.days,
    required this.schedule,
    required this.is24Hours,
    required this.onPickTime,
    required this.onToggleGender,
  });

  final List<String> days;
  final Map<String, _DaySchedule> schedule;
  final bool is24Hours;
  final _PickTimeCallback? onPickTime;
  final _ToggleGenderCallback? onToggleGender;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جدول أوقات العمل (رجال / سيدات)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ...days.map((day) {
            final d = schedule[day] ?? _DaySchedule.empty();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayRow(
                day: day,
                men: d.men,
                women: d.women,
                is24Hours: is24Hours,
                onPickTime: onPickTime,
                onToggleGender: onToggleGender,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.men,
    required this.women,
    required this.is24Hours,
    required this.onPickTime,
    required this.onToggleGender,
  });

  final String day;
  final _GenderHours men;
  final _GenderHours women;
  final bool is24Hours;
  final _PickTimeCallback? onPickTime;
  final _ToggleGenderCallback? onToggleGender;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _GenderHoursEditor(
                title: 'رجال',
                gender: _GymGender.men,
                day: day,
                value: men,
                is24Hours: is24Hours,
                onPickTime: onPickTime,
                onToggleGender: onToggleGender,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GenderHoursEditor(
                title: 'سيدات',
                gender: _GymGender.women,
                day: day,
                value: women,
                is24Hours: is24Hours,
                onPickTime: onPickTime,
                onToggleGender: onToggleGender,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderHoursEditor extends StatelessWidget {
  const _GenderHoursEditor({
    required this.title,
    required this.gender,
    required this.day,
    required this.value,
    required this.is24Hours,
    required this.onPickTime,
    required this.onToggleGender,
  });

  final String title;
  final _GymGender gender;
  final String day;
  final _GenderHours value;
  final bool is24Hours;
  final _PickTimeCallback? onPickTime;
  final _ToggleGenderCallback? onToggleGender;

  String _fmt(TimeOfDay? t) {
    if (t == null) return '--:--';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !is24Hours;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Switch(
                value: value.enabled,
                onChanged: canEdit && onToggleGender != null
                    ? (v) => onToggleGender!(day, gender, v)
                    : null,
                activeThumbColor: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canEdit && value.enabled && onPickTime != null
                      ? () => onPickTime!(day, gender, true)
                      : null,
                  child: Text('من: ${_fmt(value.from)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: canEdit && value.enabled && onPickTime != null
                      ? () => onPickTime!(day, gender, false)
                      : null,
                  child: Text('إلى: ${_fmt(value.to)}'),
                ),
              ),
            ],
          ),
          if (is24Hours)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '24 ساعة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
