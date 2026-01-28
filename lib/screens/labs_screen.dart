import 'package:flutter/material.dart';

import '../models/lab_model.dart';
import 'lab_details_screen.dart';
import 'add_lab_screen.dart';
import 'lab_login_screen.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<String> _serviceFilters = const [
    'تحاليل عامة',
    'أشعة',
    'PCR/كوفيد',
    'نتائج سريعة',
    'يعمل 24 ساعة',
  ];

  final Set<String> _selectedServices = <String>{};

  late final List<_LabData> _allLabs = <_LabData>[
    _LabData(
      model: const LabModel(
        id: 'fayoum',
        name: 'معمل الفيوم',
        address: 'الفيوم - شارع الحرية',
        phone: '084-6350000',
        rating: 4.5,
        ratingCount: 120,
        workingHours: 'يومياً 8 ص - 10 م',
        features: [
          'نتائج خلال ساعتين',
          'سحب عينات من المنزل',
          'نتائج على الواتساب',
          'خصم 20% للفحوصات الشاملة',
        ],
        tests: {
          'تحاليل روتينية': [
            'صورة دم كاملة',
            'سكر صائم وفاطر',
            'وظائف كلى',
            'وظائف كبد',
          ],
          'تحاليل متخصصة': [
            'هرمونات الغدة الدرقية',
            'دلالات أورام',
            'تحليل مناعة',
            'فيتامينات ومعادن',
          ],
        },
        offers: 'خصم 20% على الفحوصات الشاملة',
      ),
      icon: Icons.biotech,
      color: const Color(0xFF9C27B0),
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

  List<_LabData> get _filtered {
    if (_selectedServices.isEmpty) return _allLabs;

    return _allLabs.where((lab) {
      return _selectedServices.every(
        (s) => lab.model.features.any((feat) => feat.contains(s)),
      );
    }).toList();
  }

  void _openDetails(_LabData lab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LabDetailsScreen(lab: lab.model)),
    );
  }

  Future<void> _openAddLabScreen() async {
    // فتح صفحة تسجيل الدخول أولاً
    final loginSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LabLoginScreen()),
    );

    // إذا نجح تسجيل الدخول، فتح صفحة إضافة المعمل
    if (loginSuccess == true && mounted) {
      final result = await Navigator.push<LabModel>(
        context,
        MaterialPageRoute(builder: (context) => const AddLabScreen()),
      );

      if (result != null && mounted) {
        setState(() {
          _allLabs.add(
            _LabData(
              model: result,
              icon: Icons.biotech,
              color: const Color(0xFF9C27B0),
            ),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم إضافة المعمل بنجاح')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labs = _filtered;

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
                const Color(0xFF9C27B0).withValues(alpha: 0.03),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildStatsSection(labs.length),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: labs.isEmpty
                      ? _buildEmptyState()
                      : _buildLabsList(labs),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المعامل الطبية',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                Text(
                  'محافظة الفيوم',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.biotech, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              onPressed: _openAddLabScreen,
              tooltip: 'إضافة معمل',
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
                const Color(0xFF9C27B0).withValues(alpha: 0.1),
                const Color(0xFF00BCD4).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
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
                  Icons.science,
                  color: Color(0xFF9C27B0),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count معمل طبي',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'تحاليل دقيقة ونتائج سريعة',
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
            'جرّب تعديل الفلاتر',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLabsList(List<_LabData> labs) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      itemCount: labs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / labs.length) * 0.5,
                    ((index + 1) / labs.length) * 0.5 + 0.5,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
          child: FadeTransition(
            opacity: _animationController,
            child: _LabCardWidget(
              lab: labs[index],
              onTap: () => _openDetails(labs[index]),
            ),
          ),
        );
      },
    );
  }
}

class _LabData {
  final LabModel model;
  final IconData icon;
  final Color color;

  const _LabData({
    required this.model,
    required this.icon,
    required this.color,
  });
}

class _LabCardWidget extends StatelessWidget {
  const _LabCardWidget({required this.lab, required this.onTap});

  final _LabData lab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: lab.color.withValues(alpha: 0.2),
        highlightColor: lab.color.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, lab.color.withValues(alpha: 0.03)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: lab.color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: lab.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            lab.color.withValues(alpha: 0.2),
                            lab.color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: lab.color.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(lab.icon, color: lab.color, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lab.model.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (lab.model.rating != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lab.model.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (lab.model.ratingCount != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${lab.model.ratingCount})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lab.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: lab.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (lab.model.address?.trim().isNotEmpty == true) ...[
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
                          lab.model.address!.trim(),
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
                  const SizedBox(height: 8),
                ],
                if (lab.model.workingHours?.trim().isNotEmpty == true) ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: lab.color),
                      const SizedBox(width: 6),
                      Text(
                        lab.model.workingHours!.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: lab.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (lab.model.features.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: lab.model.features.take(3).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lab.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lab.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: lab.color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: lab.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: lab.color),
                      const SizedBox(width: 6),
                      Text(
                        'اضغط لعرض التفاصيل الكاملة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: lab.color,
                        ),
                      ),
                    ],
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
