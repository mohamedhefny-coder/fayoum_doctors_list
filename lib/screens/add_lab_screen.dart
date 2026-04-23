import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/lab_media_service.dart';
import '../services/lab_service.dart';

class AddLabScreen extends StatefulWidget {
  const AddLabScreen({super.key});

  @override
  State<AddLabScreen> createState() => _AddLabScreenState();
}

class _AddLabScreenState extends State<AddLabScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _offersController = TextEditingController();
  final _contractsController = TextEditingController();
  final _labService = LabService();
  final _labMediaService = LabMediaService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  XFile? _coverImageFile;
  Uint8List? _coverImageBytes;

  XFile? _logoImageFile;
  Uint8List? _logoImageBytes;

  final List<XFile> _galleryImageFiles = <XFile>[];
  final List<Uint8List> _galleryImageBytes = <Uint8List>[];

  final List<String> _features = [];
  static const List<String> _availableFeatures = [
    'نتائج في نفس اليوم',
    'خدمة سحب عينات من المنزل',
    'سحب عينات للأطفال',
    'إمكانية الدفع أونلاين',
    'خصومات للمتابعة',
    'نتائج عبر واتساب',
    'نتائج عبر البريد الإلكتروني',
    'تعاقدات مع شركات/تأمين',
    'خدمة عملاء على مدار اليوم',
    'استقبال حالات طوارئ',
  ];

  static const Map<String, List<String>> _availableTests = {
    'تحاليل روتينية': [
      'صورة دم كاملة (CBC)',
      'تحليل سكر صائم',
      'تحليل سكر فاطر',
      'سكر تراكمي (HbA1c)',
      'تحليل بول كامل',
      'تحليل براز كامل',
      'وظائف كبد (ALT/AST)',
      'وظائف كلى (Urea/Creatinine)',
      'دهون الدم (Chol/Trig)',
      'فصيلة الدم (ABO/Rh)',
      'HBsAg',
      'HCV Ab',
    ],
    'تحاليل متخصصة': [
      'CRP',
      'ESR',
      'D-Dimer',
      'Ferritin',
      'Vitamin D',
      'Vitamin B12',
      'TSH',
      'Free T3',
      'Free T4',
      'Prolactin',
      'FSH',
      'LH',
      'Testosterone',
      'Beta-hCG',
      'PSA',
    ],
  };

  late final Map<String, Set<String>> _selectedTestsByCategory = {
    for (final key in _availableTests.keys) key: <String>{},
  };

  final _featureController = TextEditingController();

  final _customTestController = TextEditingController();
  final List<String> _customTests = <String>[];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _workingHoursController.dispose();
    _offersController.dispose();
    _contractsController.dispose();
    _featureController.dispose();
    _customTestController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final text = _featureController.text.trim();
    if (text.isNotEmpty && !_features.contains(text)) {
      setState(() {
        _features.add(text);
        _featureController.clear();
      });
    }
  }

  void _removeFeature(String item) {
    setState(() => _features.remove(item));
  }

  void _toggleCommonFeature(String item, bool selected) {
    setState(() {
      if (selected) {
        if (!_features.contains(item)) {
          _features.add(item);
        }
      } else {
        _features.remove(item);
      }
    });
  }

  void _addCustomTest() {
    final text = _customTestController.text.trim();
    if (text.isEmpty) return;

    final existsInCustom = _customTests.any(
      (t) => t.trim().toLowerCase() == text.toLowerCase(),
    );
    if (existsInCustom) {
      _customTestController.clear();
      return;
    }

    setState(() {
      _customTests.add(text);
      _customTestController.clear();
    });
  }

  void _removeCustomTest(String item) {
    setState(() => _customTests.remove(item));
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

  Future<void> _pickLogoImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _logoImageFile = picked;
      _logoImageBytes = bytes;
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

  void _toggleTestSelection(String category, String test) {
    final set = _selectedTestsByCategory[category];
    if (set == null) return;
    setState(() {
      if (set.contains(test)) {
        set.remove(test);
      } else {
        set.add(test);
      }
    });
  }

  void _selectAllTestsInCategory(String category) {
    final available = _availableTests[category] ?? const <String>[];
    setState(() {
      _selectedTestsByCategory[category] = available.toSet();
    });
  }

  void _clearAllTestsInCategory(String category) {
    setState(() {
      _selectedTestsByCategory[category] = <String>{};
    });
  }

  Future<void> _saveLabData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('💾 Saving lab data...');
      debugPrint('💾 Name: ${_nameController.text.trim()}');
      debugPrint('💾 Features: $_features');

      final testsToSave = <String, List<String>>{};
      for (final entry in _selectedTestsByCategory.entries) {
        final list = entry.value.toList()..sort();
        if (list.isNotEmpty) {
          testsToSave[entry.key] = list;
        }
      }
      if (_customTests.isNotEmpty) {
        final list = _customTests.toList()..sort();
        testsToSave['أخرى'] = list;
      }
      debugPrint('💾 Tests: $testsToSave');

      String? coverUrl;
      String? logoUrl;
      List<String>? galleryUrls;

      if (_coverImageFile != null) {
        coverUrl = await _labMediaService.uploadImage(_coverImageFile!, 'cover');
      }
      if (_logoImageFile != null) {
        logoUrl = await _labMediaService.uploadImage(_logoImageFile!, 'logo');
      }
      if (_galleryImageFiles.isNotEmpty) {
        final urls = <String>[];
        for (final f in _galleryImageFiles) {
          urls.add(await _labMediaService.uploadImage(f, 'gallery'));
        }
        galleryUrls = urls;
      }

      // حفظ بيانات المعمل في Supabase
      await _labService.upsertLabData(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        whatsapp: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        workingHours: _workingHoursController.text.trim().isNotEmpty
            ? _workingHoursController.text.trim()
            : null,
        offers: _offersController.text.trim().isNotEmpty
            ? _offersController.text.trim()
            : null,
        contracts: _contractsController.text.trim().isNotEmpty
            ? _contractsController.text.trim()
            : null,
        coverImageUrl: coverUrl,
        logoImageUrl: logoUrl,
        galleryImageUrls: galleryUrls,
        features: _features.isNotEmpty ? _features : null,
        tests: testsToSave.isNotEmpty ? testsToSave : null,
      );

      debugPrint('💾 Lab data saved successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ بيانات المعمل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('💾 Error saving lab data: $e');
      if (mounted) {
        // استخرج الرسالة الحقيقية من الخطأ
        String errorMsg = e.toString();
        if (errorMsg.contains('Exception: ')) {
          errorMsg = errorMsg.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة معمل جديد'),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: _saveLabData,
                icon: const Icon(Icons.check),
                label: const Text('حفظ'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPageHeader(colorScheme),
              const SizedBox(height: 16),
              _buildImagesSection(colorScheme),
              _buildBasicInfoSection(colorScheme),
              const SizedBox(height: 20),
              _buildFeaturesSection(colorScheme),
              const SizedBox(height: 20),
              _buildTestsSection(colorScheme),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Icon(Icons.biotech, color: colorScheme.primary, size: 30),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملف المعمل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'أضف صور المعمل واختر التحاليل من القائمة متعددة الاختيار.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'صور المعمل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cover
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'كفر المعمل',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_coverImageBytes != null)
                          Image.memory(_coverImageBytes!, fit: BoxFit.cover)
                        else
                          Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              color: colorScheme.outline,
                              size: 42,
                            ),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isLoading ? null : _pickCoverImage,
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    _coverImageFile == null
                                        ? 'اختيار صورة الكفر'
                                        : 'تغيير صورة الكفر',
                                  ),
                                ),
                              ),
                              if (_coverImageFile != null) ...[
                                const SizedBox(width: 10),
                                IconButton.filledTonal(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _coverImageFile = null;
                                            _coverImageBytes = null;
                                          });
                                        },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
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

          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوجو المعمل',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _logoImageBytes != null
                          ? Image.memory(_logoImageBytes!, fit: BoxFit.cover)
                          : Icon(
                              Icons.apartment,
                              color: colorScheme.outline,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickLogoImage,
                        icon: const Icon(Icons.upload_outlined),
                        label: Text(
                          _logoImageFile == null
                              ? 'اختيار لوجو'
                              : 'تغيير اللوجو',
                        ),
                      ),
                    ),
                    if (_logoImageFile != null) ...[
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _logoImageFile = null;
                                  _logoImageBytes = null;
                                });
                              },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Gallery
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'معرض الصور',
                        style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickGalleryImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('إضافة صور'),
                    ),
                  ],
                ),
                if (_galleryImageFiles.isEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'يمكنك إضافة أكثر من صورة لعرض المعمل.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_galleryImageFiles.length, (i) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _galleryImageBytes[i],
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: InkWell(
                              onTap: _isLoading ? null : () => _removeGalleryImageAt(i),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'المعلومات الأساسية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المعمل *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.biotech),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'يرجى إدخال العنوان' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'يرجى إدخال رقم الهاتف'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الواتساب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.chat),
                    hintText: 'مثال: 01234567890',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'مثال: lab@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _workingHoursController,
                  decoration: const InputDecoration(
                    labelText: 'ساعات العمل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                    hintText: 'مثال: يومياً 8 ص - 10 م',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _offersController,
                  decoration: const InputDecoration(
                    labelText: 'العروض',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_offer),
                    hintText: 'مثال: خصم 20% على الفحوصات الشاملة',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contractsController,
                  decoration: const InputDecoration(
                    labelText: 'التعاقدات',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.handshake),
                    hintText: 'مثال: التأمين الصحي، الشركات، الجهات الحكومية',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star_border, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'المميزات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اختر من المميزات الشائعة',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableFeatures.map((item) {
                    final isSelected = _features.contains(item);
                    return FilterChip(
                      label: Text(item),
                      selected: isSelected,
                      onSelected:
                          _isLoading ? null : (v) => _toggleCommonFeature(item, v),
                      showCheckmark: true,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _featureController,
                        decoration: const InputDecoration(
                          labelText: 'إضافة ميزة',
                          border: OutlineInputBorder(),
                          hintText: 'مثال: نتائج سريعة',
                        ),
                        onSubmitted: (_) => _addFeature(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addFeature,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _features
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeFeature(item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsSection(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'التحاليل المتاحة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._availableTests.entries.map((entry) {
            final category = entry.key;
            final available = entry.value;
            final selected = _selectedTestsByCategory[category] ?? <String>{};
            final isLast = category == _availableTests.keys.last;

            return Column(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            '${selected.length}/${available.length}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _selectAllTestsInCategory(category),
                            child: const Text('تحديد الكل'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _clearAllTestsInCategory(category),
                            child: const Text('إلغاء الكل'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: available.map((test) {
                          final isSelected = selected.contains(test);
                          return FilterChip(
                            label: Text(test),
                            selected: isSelected,
                            onSelected: _isLoading
                                ? null
                                : (_) => _toggleTestSelection(category, test),
                            showCheckmark: true,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أخرى',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'أضف أي تحليل إضافي يقدمه المعمل.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customTestController,
                        decoration: const InputDecoration(
                          labelText: 'اسم التحليل',
                          border: OutlineInputBorder(),
                          hintText: 'مثال: تحليل حساسية الغذاء',
                        ),
                        onSubmitted: (_) => _addCustomTest(),
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isLoading ? null : _addCustomTest,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_customTests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customTests
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted:
                                _isLoading ? null : () => _removeCustomTest(item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
