import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_service.dart';
import '../services/medical_supplies_media_service.dart';

class AdminAddMedicalSuppliesStoreScreen extends StatefulWidget {
  const AdminAddMedicalSuppliesStoreScreen({super.key});

  @override
  State<AdminAddMedicalSuppliesStoreScreen> createState() =>
      _AdminAddMedicalSuppliesStoreScreenState();
}

class _AdminAddMedicalSuppliesStoreScreenState
    extends State<AdminAddMedicalSuppliesStoreScreen> {
  static const primary = Color(0xFF0284C7);

  final _adminService = AdminService();
  final _mediaService = MedicalSuppliesMediaService();
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _hoursController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _newSupplyController = TextEditingController();
  final _galleryController = TextEditingController();
  final _offersController = TextEditingController();
  final _contractsController = TextEditingController();
  final _geoLocationController = TextEditingController();
  final _facebookController = TextEditingController();

  final List<String> _suppliesList = <String>[];
  bool _hasDeliveryService = false;
  bool _publishNow = false;

  bool _isSubmitting = false;
  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;

  Future<void> _pickAndUploadCover() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() => _isUploadingCover = true);

      final url = await _mediaService.uploadImage(picked, 'cover');
      if (!mounted) return;
      setState(() => _coverImageController.text = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفع صورة الكفر بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع صورة الكفر: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadGallery() async {
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;

      if (!mounted) return;
      setState(() => _isUploadingGallery = true);

      final urls = <String>[];
      for (final img in picked) {
        final url = await _mediaService.uploadImage(img, 'gallery');
        urls.add(url);
      }

      if (!mounted) return;
      final existing = _splitList(_galleryController.text);
      final combined = [...existing, ...urls];
      setState(() => _galleryController.text = combined.join('\n'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع ${urls.length} صورة للمعرض'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع صور المعرض: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _hoursController.dispose();
    _coverImageController.dispose();
    _newSupplyController.dispose();
    _galleryController.dispose();
    _offersController.dispose();
    _contractsController.dispose();
    _geoLocationController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  InputDecoration _deco({required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  List<String> _splitList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addSupply() {
    final supply = _newSupplyController.text.trim();
    if (supply.isEmpty) return;
    setState(() {
      _suppliesList.add(supply);
      _newSupplyController.clear();
    });
  }

  void _removeSupply(int index) {
    setState(() {
      _suppliesList.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final gallery = _splitList(_galleryController.text);
      final cover = _coverImageController.text.trim();
      final whatsapp = _whatsappController.text.trim();
      final offers = _offersController.text.trim();
      final contracts = _contractsController.text.trim();
      final geo = _geoLocationController.text.trim();
      final facebook = _facebookController.text.trim();

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': whatsapp.isEmpty ? null : whatsapp,
        'working_hours': _hoursController.text.trim(),
        'cover_image_url': cover.isEmpty ? null : cover,
        'available_supplies': _suppliesList.isEmpty ? null : [..._suppliesList],
        'gallery_image_urls': gallery.isEmpty ? null : gallery,
        'offers_and_discounts': offers.isEmpty ? null : offers,
        'has_delivery_service': _hasDeliveryService,
        'available_contracts': contracts.isEmpty ? null : contracts,
        'geo_location': geo.isEmpty ? null : geo,
        'facebook_page': facebook.isEmpty ? null : facebook,
        'is_published': _publishNow,
      };

      await _adminService.createMedicalSuppliesStore(data: data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_publishNow
              ? 'تم إضافة المتجر ونشره بنجاح'
              : 'تم إضافة المتجر بنجاح (غير منشور) طويلًا'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0EA5E9).withValues(alpha: 0.05),
                const Color(0xFFF1F5F9),
                const Color(0xFF0284C7).withValues(alpha: 0.04),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 20),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          tooltip: 'رجوع',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة متجر مستلزمات (مدير)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'إضافة المتجر وإعداد النشر من لوحة المدير',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), primary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/medical_supplies.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.healing,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _sectionCard(
                            title: 'إعدادات النشر',
                            icon: Icons.public,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primary.withValues(alpha: 0.10),
                                    const Color(0xFF0EA5E9)
                                        .withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: SwitchListTile.adaptive(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                title: const Text(
                                  'نشر المتجر الآن',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: const Text(
                                  'إذا كان غير منشور لن يظهر للمستخدمين',
                                ),
                                value: _publishNow,
                                onChanged: _isSubmitting
                                    ? null
                                    : (v) => setState(() => _publishNow = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            title: 'بيانات أساسية',
                            icon: Icons.storefront_outlined,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _deco(
                                    label: 'اسم المتجر *',
                                    icon: Icons.store,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'من فضلك أدخل اسم المتجر';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: _deco(
                                    label: 'العنوان التفصيلي *',
                                    icon: Icons.location_on_outlined,
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
                                  decoration: _deco(
                                    label: 'رقم الهاتف *',
                                    icon: Icons.phone_outlined,
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
                                  decoration: _deco(
                                    label: 'رقم واتساب (اختياري)',
                                    icon: Icons.chat_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _hoursController,
                                  decoration: _deco(
                                    label: 'أوقات العمل *',
                                    hint: 'مثال: يومياً 10 ص - 10 م',
                                    icon: Icons.access_time,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'من فضلك أدخل أوقات العمل';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            title: 'تفاصيل إضافية',
                            icon: Icons.tune,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _coverImageController,
                                  decoration: _deco(
                                    label: 'صورة الكفر (رابط/مسار) (اختياري)',
                                    hint: 'مثال: https://... أو assets/...',
                                    icon: Icons.image_outlined,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: (_isSubmitting || _isUploadingCover)
                                        ? null
                                        : _pickAndUploadCover,
                                    icon: _isUploadingCover
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.upload),
                                    label: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text('اختيار ورفع صورة الكفر'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'المستلزمات المتوفرة (اختياري)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _newSupplyController,
                                        decoration: _deco(
                                          label: 'أدخل مستلزم',
                                          icon: Icons.medical_services_outlined,
                                        ),
                                        onSubmitted: (_) => _addSupply(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : _addSupply,
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
                                if (_suppliesList.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _suppliesList.asMap().entries.map((e) {
                                      final index = e.key;
                                      final supply = e.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  supply,
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
                                                onTap: _isSubmitting
                                                    ? null
                                                    : () => _removeSupply(index),
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
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _galleryController,
                                  maxLines: 3,
                                  decoration: _deco(
                                    label: 'معرض الصور (روابط/مسارات) (اختياري)',
                                    hint: 'افصل بين الروابط بسطر جديد أو فاصلة',
                                    icon: Icons.collections_outlined,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: (_isSubmitting || _isUploadingGallery)
                                        ? null
                                        : _pickAndUploadGallery,
                                    icon: _isUploadingGallery
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.collections),
                                    label: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text('إضافة صور للمعرض (رفع من الجهاز)'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _offersController,
                                  maxLines: 3,
                                  decoration: _deco(
                                    label: 'العروض والخصومات (اختياري)',
                                    icon: Icons.local_offer_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primary.withValues(alpha: 0.10),
                                        const Color(0xFF0EA5E9)
                                            .withValues(alpha: 0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: SwitchListTile.adaptive(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    title: const Text(
                                      'خدمة التوصيل متاحة',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    value: _hasDeliveryService,
                                    onChanged: _isSubmitting
                                        ? null
                                        : (v) => setState(() =>
                                            _hasDeliveryService = v),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contractsController,
                                  maxLines: 2,
                                  decoration: _deco(
                                    label: 'التعاقدات المتاحة (اختياري)',
                                    hint: 'مثال: تأمين/نقابات/شركات',
                                    icon: Icons.handshake_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _geoLocationController,
                                  decoration: _deco(
                                    label: 'الموقع الجغرافي (اختياري)',
                                    hint: 'مثال: 29.3084, 30.8428',
                                    icon: Icons.my_location_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _facebookController,
                                  decoration: _deco(
                                    label: 'صفحة فيسبوك (اختياري)',
                                    hint: 'https://facebook.com/...',
                                    icon: Icons.facebook,
                                  ),
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
                                  'حفظ المتجر',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
