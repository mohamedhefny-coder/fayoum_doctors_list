import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/hospital_media_service.dart';
import '../services/hospital_service.dart';

class AddHospitalScreen extends StatefulWidget {
  const AddHospitalScreen({super.key});

  @override
  State<AddHospitalScreen> createState() => _AddHospitalScreenState();
}

class _AddHospitalScreenState extends State<AddHospitalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _geoLocationController = TextEditingController();
  final _facebookController = TextEditingController();
  final _notesController = TextEditingController();

  final _hospitalService = HospitalService();
  final _mediaService = HospitalMediaService();
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  XFile? _coverImageFile;
  Uint8List? _coverImageBytes;

  final List<XFile> _galleryImageFiles = <XFile>[];
  final List<Uint8List> _galleryImageBytes = <Uint8List>[];

  bool _hasEmergency24 = false;

  static const List<String> _departments = <String>[
    'الطوارئ',
    'العناية المركزة',
    'الحضّانات',
    'العمليات',
    'العيادات المتخصصة',
    'الأشعة',
    'المعمل',
    'غسيل كلوي',
    'مناظير',
    'قلب وأوعية دموية',
    'عظام',
    'أطفال',
    'نساء وتوليد',
    'أسنان',
    'جلدية',
    'مخ وأعصاب',
    'باطنة',
    'صدرية',
    'جراحة عامة',
    'صيدلية',
    'بنك دم',
  ];

  final Set<String> _selectedDepartments = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _geoLocationController.dispose();
    _facebookController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر الأقسام المتوفرة بالمستشفى'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
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
      final notes = _notesController.text.trim();

      String? coverUrl;
      if (_coverImageFile != null) {
        coverUrl = await _mediaService.uploadImage(_coverImageFile!, 'cover');
      }

      final galleryUrls = <String>[];
      for (final img in _galleryImageFiles) {
        galleryUrls.add(await _mediaService.uploadImage(img, 'gallery'));
      }

      await _hospitalService.upsertHospitalData(
        name: name,
        address: address.isEmpty ? null : address,
        phone: phone.isEmpty ? null : phone,
        whatsapp: whatsapp.isEmpty ? null : whatsapp,
        geoLocation: geoLocation.isEmpty ? null : geoLocation,
        facebookUrl: facebookUrl.isEmpty ? null : facebookUrl,
        notes: notes.isEmpty ? null : notes,
        hasEmergency24: _hasEmergency24,
        departments: _selectedDepartments.toList(),
        coverImageUrl: coverUrl,
        galleryImageUrls: galleryUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بيانات المستشفى بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ بيانات المستشفى: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة مستشفى خاص')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        _MediaSection(
                          coverBytes: _coverImageBytes,
                          galleryBytes: _galleryImageBytes,
                          onPickCover: _isSubmitting ? null : _pickCoverImage,
                          onPickGallery: _isSubmitting
                              ? null
                              : _pickGalleryImages,
                          onRemoveGalleryAt: _isSubmitting
                              ? null
                              : _removeGalleryImageAt,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستشفى *',
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'من فضلك أدخل اسم المستشفى';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان التفصيلي *',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'من فضلك أدخل العنوان';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف *',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'من فضلك أدخل رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الواتساب (اختياري)',
                            prefixIcon: Icon(Icons.chat_bubble_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _geoLocationController,
                          decoration: const InputDecoration(
                            labelText: 'الموقع الجغرافي (اختياري)',
                            hintText: 'مثال: 29.3084, 30.8428',
                            prefixIcon: Icon(Icons.my_location_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _facebookController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'رابط صفحة فيسبوك (اختياري)',
                            hintText: 'https://facebook.com/...',
                            prefixIcon: Icon(Icons.facebook),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الأقسام المتوفرة *',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _departments.map((d) {
                            final selected = _selectedDepartments.contains(d);
                            return FilterChip(
                              label: Text(d),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedDepartments.add(d);
                                  } else {
                                    _selectedDepartments.remove(d);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedDepartments.isEmpty
                              ? 'اختر قسم واحد على الأقل'
                              : 'تم اختيار: ${_selectedDepartments.length} قسم',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات إضافية (اختياري)',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('يوجد طوارئ 24 ساعة'),
                          value: _hasEmergency24,
                          onChanged: (v) => setState(() => _hasEmergency24 = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'حفظ المستشفى',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.primary.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الصور',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 10),
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
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(coverBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (galleryBytes.isNotEmpty) ...[
            const Text(
              'معرض الصور',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: galleryBytes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          galleryBytes[index],
                          width: 86,
                          height: 86,
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
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.55,
                            ),
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
        ],
      ),
    );
  }
}
