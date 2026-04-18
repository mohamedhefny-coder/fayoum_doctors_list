import 'package:flutter/material.dart';

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
  final _hoursController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final Set<String> _selectedFeatures = <String>{};

  String? _gymType;
  bool _is24Hours = false;
  bool _hasParking = false;

  static const _gymTypes = <String>['رجالي', 'سيدات', 'مختلط'];

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
    _hoursController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _completion {
    int done = 0;
    const total = 6;

    if (_nameController.text.trim().isNotEmpty) done++;
    if (_addressController.text.trim().isNotEmpty) done++;
    if (_phoneController.text.trim().isNotEmpty) done++;
    if (_hoursController.text.trim().isNotEmpty || _is24Hours) done++;
    if (_gymType != null) done++;
    if (_selectedFeatures.isNotEmpty) done++;

    return done / total;
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

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ بيانات الجيم (Demo) بنجاح'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
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
        borderSide: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
        ),
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
                      onPressed: _submit,
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
                                    const Color(0xFF22C55E)
                                        .withValues(alpha: 0.18),
                                    const Color(0xFF16A34A)
                                        .withValues(alpha: 0.10),
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
                                      backgroundColor:
                                          const Color(0xFF16A34A)
                                              .withValues(alpha: 0.10),
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
                                  DropdownButtonFormField<String>(
                                    initialValue: _gymType,
                                    decoration: _inputDecoration(
                                      label: 'نوع الجيم *',
                                      hint: 'اختر النوع',
                                      icon: Icons.groups_rounded,
                                    ),
                                    items: _gymTypes
                                        .map(
                                          (t) => DropdownMenuItem<String>(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      _gymType = v;
                                    }),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'من فضلك اختر نوع الجيم';
                                      }
                                      return null;
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
                                ],
                              ),
                            ),
                            _cardSection(
                              title: 'مواعيد العمل والاشتراكات',
                              icon: Icons.schedule_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _hoursController,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: 'أوقات العمل',
                                      hint: 'مثال: يومياً 10 ص - 12 م',
                                      icon: Icons.access_time_rounded,
                                    ),
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
                                          }),
                                          activeThumbColor:
                                              const Color(0xFF16A34A),
                                          activeTrackColor:
                                              const Color(0xFF16A34A)
                                                  .withValues(alpha: 0.35),
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
                                      final isSelected =
                                          _selectedFeatures.contains(f);
                                      return InkWell(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        onTap: () => _toggleFeature(f),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 160),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF16A34A)
                                                    .withValues(alpha: 0.12)
                                                : const Color(0xFF0F172A)
                                                    .withValues(alpha: 0.04),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF16A34A)
                                                      .withValues(alpha: 0.35)
                                                  : Colors.black
                                                      .withValues(alpha: 0.08),
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
                                    activeTrackColor: const Color(0xFF16A34A)
                                        .withValues(alpha: 0.35),
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
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'حفظ بيانات الجيم',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ملاحظة: هذه الشاشة للعرض فقط حالياً وسيتم ربطها بقاعدة البيانات لاحقاً.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                              textAlign: TextAlign.center,
                            ),
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
