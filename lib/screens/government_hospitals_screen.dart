import 'package:flutter/material.dart';

import '../models/hospital_model.dart';
import 'hospital_details_screen.dart';

class GovernmentHospitalsScreen extends StatefulWidget {
  const GovernmentHospitalsScreen({super.key});

  @override
  State<GovernmentHospitalsScreen> createState() =>
      _GovernmentHospitalsScreenState();
}

class _GovernmentHospitalsScreenState extends State<GovernmentHospitalsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<String> _serviceFilters = const [
    'طوارئ',
    'أشعة',
    'معمل',
    'عيادات خارجية',
    'حضّانات',
  ];

  final Set<String> _selectedServices = <String>{};

  late final List<_HospitalData> _allHospitals = <_HospitalData>[
    _HospitalData(
      model: const HospitalModel(
        id: 'general_hospital',
        name: 'المستشفى العام',
        address: 'الفيوم - شارع الحرية',
        phone: '084-6342355',
        services: <String>['طوارئ', 'أشعة', 'معمل', 'عيادات خارجية'],
      ),
      icon: Icons.account_balance,
      color: const Color(0xFF1976D2),
    ),
    _HospitalData(
      model: const HospitalModel(
        id: 'university_hospital',
        name: 'مستشفى الجامعة',
        address: 'الفيوم - الجامعة',
        phone: '084-6331200',
        services: <String>['طوارئ', 'أشعة', 'معمل', 'عيادات خارجية', 'حضّانات'],
      ),
      icon: Icons.school,
      color: const Color(0xFF388E3C),
    ),
    _HospitalData(
      model: const HospitalModel(
        id: 'insurance_hospital',
        name: 'مستشفى التأمين الصحي',
        address: 'الفيوم - شارع المستشفى',
        phone: '084-6330400',
        services: <String>['عيادات خارجية', 'أشعة', 'معمل'],
      ),
      icon: Icons.shield_outlined,
      color: const Color(0xFF00838F),
    ),
    _HospitalData(
      model: const HospitalModel(
        id: 'eye_hospital',
        name: 'مستشفى الرمد',
        address: 'الفيوم - شارع الجلاء',
        phone: '084-6336200',
        services: <String>['عيون', 'عيادات خارجية'],
      ),
      icon: Icons.remove_red_eye_outlined,
      color: const Color(0xFF7B1FA2),
    ),
    _HospitalData(
      model: const HospitalModel(
        id: 'centers_hospitals',
        name: 'مستشفيات المراكز',
        address: 'مراكز الفيوم المختلفة',
        services: <String>['طوارئ', 'عيادات خارجية'],
      ),
      icon: Icons.location_city_outlined,
      color: const Color(0xFFD32F2F),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<_HospitalData> get _filtered {
    if (_selectedServices.isEmpty) return _allHospitals;

    return _allHospitals.where((h) {
      return _selectedServices.every((s) => h.model.services.contains(s));
    }).toList();
  }

  void _openDetails(_HospitalData hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalDetailsScreen(hospital: hospital.model),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hospitals = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                colorScheme.primary.withValues(alpha: 0.03),
                colorScheme.surface,
                colorScheme.secondary.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildStatsSection(hospitals.length),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: hospitals.isEmpty
                      ? _buildEmptyState()
                      : _buildHospitalsList(hospitals),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مستشفيات حكومية',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                Text(
                  'محافظة الفيوم',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_hospital,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int count) {
    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1976D2).withValues(alpha: 0.1),
                const Color(0xFF00838F).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1976D2).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.domain,
                  color: Color(0xFF1976D2),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count مستشفى حكومي',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'خدمات صحية مجانية ومدعومة',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _serviceFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = _serviceFilters[i];
          final selected = _selectedServices.contains(s);
          return FilterChip(
            label: Text(s),
            selected: selected,
            showCheckmark: true,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _selectedServices.add(s);
                } else {
                  _selectedServices.remove(s);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج مطابقة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب تعديل البحث أو الفلاتر',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalsList(List<_HospitalData> hospitals) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      itemCount: hospitals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / hospitals.length) * 0.5,
                    ((index + 1) / hospitals.length) * 0.5 + 0.5,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
          child: FadeTransition(
            opacity: _animationController,
            child: _HospitalCardWidget(
              hospital: hospitals[index],
              onTap: () => _openDetails(hospitals[index]),
            ),
          ),
        );
      },
    );
  }
}

class _HospitalData {
  final HospitalModel model;
  final IconData icon;
  final Color color;

  const _HospitalData({
    required this.model,
    required this.icon,
    required this.color,
  });
}

class _HospitalCardWidget extends StatelessWidget {
  const _HospitalCardWidget({required this.hospital, required this.onTap});

  final _HospitalData hospital;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, hospital.color.withValues(alpha: 0.03)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hospital.color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: hospital.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          hospital.color.withValues(alpha: 0.2),
                          hospital.color.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hospital.color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(hospital.icon, color: hospital.color, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.model.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hospital.model.address?.trim().isNotEmpty ==
                                        true
                                    ? hospital.model.address!.trim()
                                    : 'الفيوم',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hospital.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: hospital.color,
                    ),
                  ),
                ],
              ),
              if (hospital.model.phone?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: hospital.color),
                    const SizedBox(width: 6),
                    Text(
                      hospital.model.phone!.trim(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hospital.color,
                      ),
                    ),
                  ],
                ),
              ],
              if (hospital.model.services.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hospital.model.services.take(4).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hospital.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hospital.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getServiceIcon(s),
                            size: 14,
                            color: hospital.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hospital.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: hospital.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 16, color: hospital.color),
                    const SizedBox(width: 6),
                    Text(
                      'اضغط لعرض التفاصيل الكاملة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hospital.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String service) {
    if (service.contains('طوارئ')) return Icons.emergency;
    if (service.contains('أشعة')) return Icons.medical_information;
    if (service.contains('معمل')) return Icons.biotech;
    if (service.contains('عيادات')) return Icons.medical_services;
    if (service.contains('حضّانات')) return Icons.child_care;
    if (service.contains('عيون')) return Icons.remove_red_eye;
    return Icons.local_hospital;
  }
}
