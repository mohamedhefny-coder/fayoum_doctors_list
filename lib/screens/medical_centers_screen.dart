import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/doctor_specialties.dart';
import '../services/medical_centers_media_service.dart';

class MedicalCentersScreen extends StatefulWidget {
  const MedicalCentersScreen({super.key});

  @override
  State<MedicalCentersScreen> createState() => _MedicalCentersScreenState();
}

class _MedicalCentersScreenState extends State<MedicalCentersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<String> _serviceFilters = const [
    'عيادات متعددة',
    'عيادات طوارئ',
    'معمل تحاليل',
    'أشعة',
    'يعمل 24 ساعة',
  ];

  final Set<String> _selectedServices = <String>{};

  late final List<_MedicalCenter> _allCenters = <_MedicalCenter>[
    _MedicalCenter(
      name: 'مركز طبي الفيوم',
      address: 'الفيوم - شارع الحرية - بجوار البنك الأهلي',
      phone: '084-6340000',
      whatsappNumber: '01000000000',
      rating: 4.6,
      ratingCount: 95,
      workingHours: 'يومياً 9 ص - 11 م',
      specialties: [
        'باطنة',
        'أطفال',
        'نساء وتوليد',
        'جراحة عامة',
        'عظام',
        'أنف وأذن وحنجرة',
        'جلدية',
        'أسنان',
      ],
      services: [
        'عيادات خارجية',
        'عيادات طوارئ 24 ساعة',
        'معمل تحاليل',
        'أشعة وموجات صوتية',
        'صيدلية',
        'عمليات يومية',
      ],
      features: [
        'أطباء استشاريين',
        'أجهزة حديثة',
        'خدمة 24 ساعة',
        'أسعار مناسبة',
        'نتائج سريعة',
      ],
      geoLocation: '29.3084, 30.8428',
      facebookPage: 'https://facebook.com/',
      availableContracts: 'تأمين/نقابات/شركات (حسب التوفر)',
      offersAndDiscounts: 'خصومات موسمية وعروض على الكشف والتحاليل',
      icon: Icons.medical_services,
      color: const Color(0xFF00BCD4),
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

  List<_MedicalCenter> get _filtered {
    if (_selectedServices.isEmpty) return _allCenters;

    return _allCenters.where((center) {
      return _selectedServices.every(
        (s) =>
            center.services.any((serv) => serv.contains(s)) ||
            center.features.any((feat) => feat.contains(s)),
      );
    }).toList();
  }

  void _openDetails(_MedicalCenter center) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MedicalCenterDetailsScreen(center: center),
      ),
    );
  }

  Future<void> _openAddCenter() async {
    final newCenter = await Navigator.push<_MedicalCenter>(
      context,
      MaterialPageRoute(builder: (_) => const _AddMedicalCenterScreen()),
    );
    if (!mounted) return;
    if (newCenter == null) return;
    setState(() {
      _allCenters.add(newCenter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final centers = _filtered;

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
                const Color(0xFF00BCD4).withValues(alpha: 0.03),
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF00BCD4),
                actions: [
                  IconButton(
                    tooltip: 'إضافة مركز',
                    icon: const Icon(Icons.add),
                    onPressed: _openAddCenter,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'المراكز الطبية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          const Color(0xFF00BCD4),
                          const Color(0xFF00BCD4).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medical_services,
                        size: 80,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عداد المراكز
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00BCD4,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: Color(0xFF00BCD4),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إجمالي المراكز',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${centers.length}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00BCD4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // فلاتر الخدمات
                      const Text(
                        'تصفية حسب الخدمة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _serviceFilters.map((service) {
                          final isSelected = _selectedServices.contains(
                            service,
                          );
                          return FilterChip(
                            label: Text(service),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedServices.add(service);
                                } else {
                                  _selectedServices.remove(service);
                                }
                              });
                            },
                            selectedColor: const Color(
                              0xFF00BCD4,
                            ).withValues(alpha: 0.2),
                            checkmarkColor: const Color(0xFF00BCD4),
                            backgroundColor: Colors.white,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // قائمة المراكز
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: centers.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد مراكز مطابقة للفلاتر المحددة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final center = centers[index];
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.3, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index * 0.1,
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                            child: FadeTransition(
                              opacity: _animationController,
                              child: _MedicalCenterCard(
                                center: center,
                                onTap: () => _openDetails(center),
                              ),
                            ),
                          );
                        }, childCount: centers.length),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicalCenter {
  final String name;
  final String address;
  final String phone;
  final String? whatsappNumber;
  final double rating;
  final int ratingCount;
  final String workingHours;
  final List<String> specialties;
  final List<String> services;
  final List<String> features;
  final String? geoLocation;
  final String? facebookPage;
  final String? coverImageUrl;
  final List<String> galleryImageUrls;
  final String? availableContracts;
  final String? offersAndDiscounts;
  final IconData icon;
  final Color color;

  _MedicalCenter({
    required this.name,
    required this.address,
    required this.phone,
    this.whatsappNumber,
    required this.rating,
    required this.ratingCount,
    required this.workingHours,
    required this.specialties,
    required this.services,
    required this.features,
    this.geoLocation,
    this.facebookPage,
    this.coverImageUrl,
    this.galleryImageUrls = const <String>[],
    this.availableContracts,
    this.offersAndDiscounts,
    required this.icon,
    required this.color,
  });
}

class _MedicalCenterCard extends StatelessWidget {
  const _MedicalCenterCard({required this.center, required this.onTap});

  final _MedicalCenter center;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: center.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(center.icon, color: center.color, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${center.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' (${center.ratingCount})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      center.address,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    center.workingHours,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: center.features.take(3).map((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicalCenterDetailsScreen extends StatelessWidget {
  const _MedicalCenterDetailsScreen({required this.center});

  final _MedicalCenter center;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final cleaned = url.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = _digitsOnly(phone);
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGeoLocation(String geo) async {
    final cleaned = geo.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleaned)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  center.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        center.color,
                        center.color.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: center.coverImageUrl != null &&
                          center.coverImageUrl!.trim().isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              center.coverImageUrl!.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    center.icon,
                                    size: 100,
                                    color: Colors.white24,
                                  ),
                                );
                              },
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                          ],
                        )
                      : Center(
                          child: Icon(
                            center.icon,
                            size: 100,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // التقييم
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < center.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${center.rating} (${center.ratingCount} تقييم)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // معلومات الاتصال
                    _InfoSection(
                      icon: Icons.location_on,
                      title: 'العنوان',
                      content: center.address,
                    ),
                    const SizedBox(height: 16),
                    _InfoSection(
                      icon: Icons.access_time,
                      title: 'ساعات العمل',
                      content: center.workingHours,
                    ),
                    const SizedBox(height: 16),
                    _InfoSection(
                      icon: Icons.phone,
                      title: 'التواصل',
                      content: center.phone,
                      onTap: () => _makePhoneCall(center.phone),
                    ),
                    if (center.whatsappNumber != null &&
                        center.whatsappNumber!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        icon: Icons.chat,
                        title: 'واتساب',
                        content: center.whatsappNumber!.trim(),
                        onTap: () => _openWhatsApp(center.whatsappNumber!.trim()),
                      ),
                    ],
                    if (center.geoLocation != null &&
                        center.geoLocation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        icon: Icons.my_location,
                        title: 'الموقع الجغرافي',
                        content: center.geoLocation!.trim(),
                        onTap: () => _openGeoLocation(center.geoLocation!.trim()),
                      ),
                    ],
                    if (center.facebookPage != null &&
                        center.facebookPage!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        icon: Icons.facebook,
                        title: 'صفحة فيسبوك',
                        content: center.facebookPage!.trim(),
                        onTap: () => _openUrl(center.facebookPage!.trim()),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (center.galleryImageUrls.isNotEmpty) ...[
                      const Text(
                        'معرض الصور',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: center.galleryImageUrls.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final url = center.galleryImageUrls[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1.4,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey[500],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // التخصصات
                    const Text(
                      'التخصصات المتوفرة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: center.specialties.map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: center.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: center.color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(
                              color: center.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // الخدمات
                    const Text(
                      'الخدمات المتوفرة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...center.services.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: center.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (center.availableContracts != null &&
                        center.availableContracts!.trim().isNotEmpty) ...[
                      const Text(
                        'التعاقدات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        center.availableContracts!.trim(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (center.offersAndDiscounts != null &&
                        center.offersAndDiscounts!.trim().isNotEmpty) ...[
                      const Text(
                        'الخصومات والعروض',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        center.offersAndDiscounts!.trim(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // المميزات
                    const Text(
                      'المميزات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: center.features.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                feature,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    // زر الاتصال
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(center.phone),
                        icon: const Icon(Icons.phone),
                        label: const Text(
                          'اتصل الآن',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: center.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00BCD4), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _AddMedicalCenterScreen extends StatefulWidget {
  const _AddMedicalCenterScreen();

  @override
  State<_AddMedicalCenterScreen> createState() => _AddMedicalCenterScreenState();
}

class _AddMedicalCenterScreenState extends State<_AddMedicalCenterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mediaService = MedicalCentersMediaService();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _servicesController = TextEditingController();
  final _featuresController = TextEditingController();
  final _geoLocationController = TextEditingController();
  final _facebookController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _galleryController = TextEditingController();
  final _contractsController = TextEditingController();
  final _offersController = TextEditingController();

  bool _submitting = false;
  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;

  final Set<String> _selectedSpecialties = <String>{};
  final Set<String> _selectedFeatures = <String>{};
  int _specialtyPickerKeySeed = 0;
  int _featurePickerKeySeed = 0;

  static const List<String> _featureOptions = <String>[
    'أطباء استشاريين',
    'أطباء متخصصين',
    'أجهزة حديثة',
    'خدمة 24 ساعة',
    'استقبال طوارئ',
    'معمل تحاليل',
    'أشعة وموجات صوتية',
    'صيدلية',
    'عمليات يومية',
    'نتائج سريعة',
    'أسعار مناسبة',
    'أماكن انتظار مريحة',
  ];

  final Color _brandColor = const Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onMediaChanged);
    _addressController.addListener(_onMediaChanged);
    _phoneController.addListener(_onMediaChanged);
    _workingHoursController.addListener(_onMediaChanged);
    _coverImageController.addListener(_onMediaChanged);
    _galleryController.addListener(_onMediaChanged);
  }

  void _onMediaChanged() {
    if (!mounted) return;
    setState(() {
      // Rebuild to update image previews.
    });
  }

  void _addSpecialty(String value) {
    setState(() {
      _selectedSpecialties.add(value);
      _specialtyPickerKeySeed++;
    });
  }

  void _removeSpecialty(String value) {
    setState(() {
      _selectedSpecialties.remove(value);
    });
  }

  void _addFeature(String value) {
    setState(() {
      _selectedFeatures.add(value);
      _featurePickerKeySeed++;
    });
  }

  void _removeFeature(String value) {
    setState(() {
      _selectedFeatures.remove(value);
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onMediaChanged);
    _addressController.removeListener(_onMediaChanged);
    _phoneController.removeListener(_onMediaChanged);
    _workingHoursController.removeListener(_onMediaChanged);
    _coverImageController.removeListener(_onMediaChanged);
    _galleryController.removeListener(_onMediaChanged);
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _workingHoursController.dispose();
    _specialtiesController.dispose();
    _servicesController.dispose();
    _featuresController.dispose();
    _geoLocationController.dispose();
    _facebookController.dispose();
    _coverImageController.dispose();
    _galleryController.dispose();
    _contractsController.dispose();
    _offersController.dispose();
    super.dispose();
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Widget _sectionTitleWithBadge(
    String title, {
    String? subtitle,
    IconData? icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _brandColor, size: 18),
            ),
          if (icon != null) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (badgeColor ?? _brandColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (badgeColor ?? _brandColor).withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor ?? _brandColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final base = OutlineInputBorder(borderRadius: BorderRadius.circular(14));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: base,
      enabledBorder: base.copyWith(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: base.copyWith(
        borderSide: BorderSide(color: _brandColor, width: 1.6),
      ),
      errorBorder: base.copyWith(
        borderSide: BorderSide(color: Colors.red[400]!, width: 1.2),
      ),
      focusedErrorBorder: base.copyWith(
        borderSide: BorderSide(color: Colors.red[400]!, width: 1.6),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _cardSection({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _brandColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }

  int get _requiredFilledCount {
    var count = 0;
    if (_nameController.text.trim().isNotEmpty) count++;
    if (_addressController.text.trim().isNotEmpty) count++;
    if (_phoneController.text.trim().isNotEmpty) count++;
    if (_workingHoursController.text.trim().isNotEmpty) count++;
    return count;
  }

  double get _requiredProgress => _requiredFilledCount / 4.0;

  List<String> _splitList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

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

  Future<void> _submit() async {
    if (_submitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _submitting = true;
    });

    final center = _MedicalCenter(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      whatsappNumber: _whatsappController.text.trim().isEmpty
        ? null
        : _whatsappController.text.trim(),
      rating: 0,
      ratingCount: 0,
      workingHours: _workingHoursController.text.trim(),
        specialties: _selectedSpecialties.toList(),
      services: _splitList(_servicesController.text),
        features: _selectedFeatures.toList(),
      geoLocation: _geoLocationController.text.trim().isEmpty
        ? null
        : _geoLocationController.text.trim(),
      facebookPage: _facebookController.text.trim().isEmpty
        ? null
        : _facebookController.text.trim(),
      coverImageUrl: _coverImageController.text.trim().isEmpty
        ? null
        : _coverImageController.text.trim(),
      galleryImageUrls: _splitList(_galleryController.text),
      availableContracts: _contractsController.text.trim().isEmpty
        ? null
        : _contractsController.text.trim(),
      offersAndDiscounts: _offersController.text.trim().isEmpty
        ? null
        : _offersController.text.trim(),
      icon: Icons.medical_services,
      color: const Color(0xFF00BCD4),
    );

    if (!mounted) return;
    Navigator.pop(context, center);
  }

  @override
  Widget build(BuildContext context) {
    final galleryUrls = _splitList(_galleryController.text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة مركز طبي'),
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  _brandColor.withValues(alpha: 0.06),
                  Theme.of(context).colorScheme.surface,
                  _brandColor.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            _brandColor,
                            _brandColor.withValues(alpha: 0.82),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بيانات المركز الطبي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'املأ البيانات الأساسية ثم أضف الصور والروابط إن وجدت',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _brandColor.withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _brandColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.checklist,
                                  color: _brandColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'اكتمال البيانات الأساسية',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _brandColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _brandColor.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                    '$_requiredFilledCount/4',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _brandColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _requiredProgress.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: _brandColor.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _cardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitleWithBadge(
                            'معلومات أساسية',
                            icon: Icons.assignment,
                            subtitle: 'الحقول الأساسية مطلوبة للحفظ',
                            badgeText: 'مطلوب',
                          ),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'اسم المركز *',
                              icon: Icons.local_hospital,
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'من فضلك أدخل اسم المركز';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'العنوان *',
                              icon: Icons.location_on,
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'من فضلك أدخل العنوان';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: 'رقم الهاتف *',
                              icon: Icons.phone,
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'من فضلك أدخل رقم الهاتف';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _workingHoursController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'ساعات العمل *',
                              hint: 'مثال: يومياً 9 ص - 11 م',
                              icon: Icons.access_time,
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'من فضلك أدخل ساعات العمل';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    _cardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitleWithBadge(
                            'التواصل والروابط',
                            icon: Icons.link,
                            subtitle: 'اختياري — يساعد المستخدم للوصول للمركز بسرعة',
                            badgeText: 'اختياري',
                            badgeColor: Colors.deepPurple,
                          ),
                          TextFormField(
                            controller: _whatsappController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: 'رقم واتساب (اختياري)',
                              icon: Icons.chat,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _geoLocationController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'الموقع الجغرافي (اختياري)',
                              hint: 'مثال: 29.3084, 30.8428',
                              icon: Icons.my_location,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _facebookController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'صفحة فيسبوك (اختياري)',
                              hint: 'https://facebook.com/...',
                              icon: Icons.facebook,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _cardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitleWithBadge(
                            'الصور',
                            icon: Icons.photo_library,
                            subtitle: 'يمكنك لصق روابط أيضاً، أو رفع من الجهاز',
                            badgeText: 'اختياري',
                            badgeColor: Colors.indigo,
                          ),
                          TextFormField(
                            controller: _coverImageController,
                            decoration: _inputDecoration(
                              label: 'صورة الكفر (اختياري)',
                              hint: 'رابط مباشر للصورة (https://...)',
                              icon: Icons.image,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_coverImageController.text.trim().isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _isHttpUrl(_coverImageController.text)
                                        ? Image.network(
                                            _coverImageController.text.trim(),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey[500],
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[100],
                                            alignment: Alignment.center,
                                            child: Text(
                                              'ضع رابط https لصورة الكفر لعرض المعاينة',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: const Text(
                                            'معاينة الكفر',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: (_submitting || _isUploadingCover)
                                  ? null
                                  : _pickAndUploadCover,
                              icon: _isUploadingCover
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text('اختيار ورفع صورة الكفر'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _galleryController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              label: 'معرض الصور (اختياري)',
                              hint: 'ضع كل رابط في سطر — أو ارفع من الجهاز',
                              icon: Icons.collections,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (galleryUrls.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  'معاينة المعرض',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _brandColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _brandColor.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Text(
                                    '${galleryUrls.length} صورة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _brandColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: galleryUrls.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final url = galleryUrls[index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: _isHttpUrl(url)
                                          ? Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    Icons
                                                        .broken_image_outlined,
                                                    color: Colors.grey[500],
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[100],
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.image_outlined,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: (_submitting || _isUploadingGallery)
                                  ? null
                                  : _pickAndUploadGallery,
                              icon: _isUploadingGallery
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_photo_alternate),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text('إضافة صور للمعرض (رفع من الجهاز)'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _cardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitleWithBadge(
                            'التخصصات والخدمات',
                            icon: Icons.fact_check,
                            subtitle: 'اكتب كل عنصر في سطر أو افصل بفاصلة',
                            badgeText: 'اختياري',
                            badgeColor: Colors.teal,
                          ),
                          DropdownButtonFormField<String>(
                            key: ValueKey<int>(_specialtyPickerKeySeed),
                            initialValue: null,
                            decoration: _inputDecoration(
                              label: 'التخصصات المتاحة (اختياري)',
                              hint: 'اختر تخصص لإضافته',
                              icon: Icons.medical_information,
                            ),
                            items: doctorSpecialties
                                .map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              final v = (value ?? '').trim();
                              if (v.isEmpty) return;
                              _addSpecialty(v);
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_selectedSpecialties.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSpecialties.map((s) {
                                return InputChip(
                                  label: Text(s),
                                  onDeleted: () => _removeSpecialty(s),
                                  backgroundColor:
                                      _brandColor.withValues(alpha: 0.10),
                                  deleteIconColor: _brandColor,
                                  labelStyle: TextStyle(
                                    color: _brandColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: _brandColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              'لم يتم اختيار تخصصات بعد',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _servicesController,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              label: 'الخدمات (اختياري)',
                              hint: 'معمل تحاليل\nأشعة\nطوارئ',
                              icon: Icons.miscellaneous_services,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _cardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitleWithBadge(
                            'التعاقدات والعروض',
                            icon: Icons.local_offer,
                            subtitle: 'اختياري — اكتب تفاصيل مختصرة وواضحة',
                            badgeText: 'اختياري',
                            badgeColor: Colors.orange,
                          ),
                          TextFormField(
                            controller: _contractsController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              label: 'التعاقدات (اختياري)',
                              hint: 'تأمين/نقابات/شركات',
                              icon: Icons.handshake,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _offersController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              label: 'الخصومات والعروض (اختياري)',
                              icon: Icons.discount,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _cardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitleWithBadge(
                            'المميزات',
                            icon: Icons.star,
                            subtitle: 'اختر من القائمة لإضافة مميزات',
                            badgeText: 'اختياري',
                            badgeColor: Colors.green,
                          ),
                          DropdownButtonFormField<String>(
                            key: ValueKey<int>(_featurePickerKeySeed),
                            initialValue: null,
                            decoration: _inputDecoration(
                              label: 'اختر ميزة لإضافتها (اختياري)',
                              hint: 'مثال: أجهزة حديثة',
                              icon: Icons.auto_awesome,
                            ),
                            items: _featureOptions
                                .map(
                                  (f) => DropdownMenuItem<String>(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              final v = (value ?? '').trim();
                              if (v.isEmpty) return;
                              _addFeature(v);
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_selectedFeatures.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedFeatures.map((f) {
                                return InputChip(
                                  label: Text(f),
                                  onDeleted: () => _removeFeature(f),
                                  backgroundColor:
                                      Colors.green.withValues(alpha: 0.10),
                                  deleteIconColor: Colors.green,
                                  labelStyle: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: Colors.green.withValues(alpha: 0.25),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              'لم يتم اختيار مميزات بعد',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_submitting ? 'جارٍ الحفظ...' : 'حفظ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
