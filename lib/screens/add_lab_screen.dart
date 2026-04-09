import 'package:flutter/material.dart';

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
  bool _isLoading = false;

  final List<String> _features = [];
  final Map<String, List<String>> _tests = {
    'تحاليل روتينية': [],
    'تحاليل متخصصة': [],
  };

  final _featureController = TextEditingController();
  final _testControllers = <String, TextEditingController>{
    'تحاليل روتينية': TextEditingController(),
    'تحاليل متخصصة': TextEditingController(),
  };

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
    for (final controller in _testControllers.values) {
      controller.dispose();
    }
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

  void _addTest(String category) {
    final controller = _testControllers[category];
    if (controller == null) return;

    final text = controller.text.trim();
    if (text.isNotEmpty && !_tests[category]!.contains(text)) {
      setState(() {
        _tests[category]!.add(text);
        controller.clear();
      });
    }
  }

  void _removeFeature(String item) {
    setState(() => _features.remove(item));
  }

  void _removeTest(String category, String item) {
    setState(() => _tests[category]!.remove(item));
  }

  Future<void> _saveLabData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('💾 Saving lab data...');
      debugPrint('💾 Name: ${_nameController.text.trim()}');
      debugPrint('💾 Features: $_features');
      debugPrint('💾 Tests: $_tests');

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
        features: _features.isNotEmpty ? _features : null,
        tests: _tests,
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
          ..._tests.entries.map((entry) {
            final category = entry.key;
            final tests = entry.value;
            final controller = _testControllers[category]!;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'إضافة تحليل',
                                border: const OutlineInputBorder(),
                                hintText: category == 'تحاليل روتينية'
                                    ? 'مثال: صورة دم كاملة'
                                    : 'مثال: هرمونات الغدة الدرقية',
                              ),
                              onSubmitted: (_) => _addTest(category),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () => _addTest(category),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (tests.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tests
                              .map(
                                (item) => Chip(
                                  label: Text(item),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeTest(category, item),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (category != _tests.keys.last) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}
