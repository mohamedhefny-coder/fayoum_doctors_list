import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RadiologyScreen extends StatefulWidget {
  const RadiologyScreen({super.key});

  @override
  State<RadiologyScreen> createState() => _RadiologyScreenState();
}

class _RadiologyScreenState extends State<RadiologyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<String> _serviceFilters = const [
    'أشعة عادية',
    'أشعة مقطعية',
    'رنين مغناطيسي',
    'موجات صوتية',
    'يعمل 24 ساعة',
  ];

  final Set<String> _selectedServices = <String>{};

  late final List<_RadiologyCenter> _allCenters = <_RadiologyCenter>[
    _RadiologyCenter(
      name: 'مركز أشعة الفيوم',
      address: 'الفيوم - شارع الجمهورية - أمام مستشفى الفيوم العام',
      phone: '084-6350000',
      rating: 4.7,
      ratingCount: 85,
      workingHours: 'يومياً 8 ص - 10 م',
      services: [
        'أشعة عادية (X-Ray)',
        'أشعة مقطعية (CT Scan)',
        'رنين مغناطيسي (MRI)',
        'موجات صوتية (Ultrasound)',
        'ماموجرام',
        'أشعة بانوراما للأسنان',
      ],
      features: [
        'أحدث الأجهزة',
        'نتائج فورية',
        'طاقم طبي متخصص',
        'خصم 15% للمتقاعدين',
      ],
      icon: Icons.medical_information,
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

  List<_RadiologyCenter> get _filtered {
    if (_selectedServices.isEmpty) return _allCenters;

    return _allCenters.where((center) {
      return _selectedServices.every(
        (s) =>
            center.services.any((serv) => serv.contains(s)) ||
            center.features.any((feat) => feat.contains(s)),
      );
    }).toList();
  }

  void _openDetails(_RadiologyCenter center) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RadiologyDetailsScreen(center: center),
      ),
    );
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
                const Color(0xFF9C27B0).withValues(alpha: 0.03),
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF9C27B0),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      tooltip: 'إضافة مركز أشعة',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _AddRadiologyCenterScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'مراكز الأشعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          const Color(0xFF9C27B0),
                          const Color(0xFF9C27B0).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medical_information,
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
                                  0xFF9C27B0,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.medical_information,
                                color: Color(0xFF9C27B0),
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
                                      color: Color(0xFF9C27B0),
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
                              0xFF9C27B0,
                            ).withValues(alpha: 0.2),
                            checkmarkColor: const Color(0xFF9C27B0),
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
                              child: _RadiologyCenterCard(
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

class _RadiologyCenter {
  final String name;
  final String address;
  final String phone;
  final double rating;
  final int ratingCount;
  final String workingHours;
  final List<String> services;
  final List<String> features;
  final IconData icon;
  final Color color;

  _RadiologyCenter({
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.ratingCount,
    required this.workingHours,
    required this.services,
    required this.features,
    required this.icon,
    required this.color,
  });
}

class _RadiologyCenterCard extends StatelessWidget {
  const _RadiologyCenterCard({required this.center, required this.onTap});

  final _RadiologyCenter center;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: center.color.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient header ──
              Container(
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      center.color,
                      center.color.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -28,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: -38,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              center.icon,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  center.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < center.rating.floor()
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${center.rating} (${center.ratingCount})',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'التفاصيل ←',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardInfoRow(
                      icon: Icons.location_on_rounded,
                      text: center.address,
                      color: center.color,
                    ),
                    const SizedBox(height: 7),
                    _CardInfoRow(
                      icon: Icons.schedule_rounded,
                      text: center.workingHours,
                      color: center.color,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: center.services.take(4).map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: center.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: center.color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            service,
                            style: TextStyle(
                              fontSize: 10,
                              color: center.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: center.phone);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: Text(center.phone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: center.color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
}

class _CardInfoRow extends StatelessWidget {
  const _CardInfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RadiologyDetailsScreen extends StatelessWidget {
  const _RadiologyDetailsScreen({required this.center});

  final _RadiologyCenter center;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5FF),
        body: CustomScrollView(
          slivers: [
            // ── Hero AppBar ──
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              elevation: 0,
              backgroundColor: center.color,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            center.color,
                            center.color.withValues(alpha: 0.6),
                            Colors.purple.shade900,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -60,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  blurRadius: 30,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              center.icon,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            center.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black38, blurRadius: 6),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Rating card ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: center.color.withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < center.rating.floor()
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${center.rating} من 5  •  ${center.ratingCount} تقييم',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  center.color,
                                  center.color.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${center.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quick action buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.phone_rounded,
                            label: 'اتصال',
                            color: Colors.green,
                            onTap: () => _makePhoneCall(center.phone),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.chat_rounded,
                            label: 'واتساب',
                            color: const Color(0xFF25D366),
                            onTap: () async {
                              final number = center.phone
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              final uri = Uri.parse(
                                'https://wa.me/$number',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.location_on_rounded,
                            label: 'الموقع',
                            color: Colors.blue,
                            onTap: () async {
                              final query = Uri.encodeComponent(center.name);
                              final uri = Uri.parse(
                                'https://maps.google.com/?q=$query',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Contact info ──
                    _DetailBlock(
                      title: 'معلومات التواصل',
                      icon: Icons.info_outline_rounded,
                      color: center.color,
                      children: [
                        _DetailRow(
                          icon: Icons.location_on_rounded,
                          text: center.address,
                          color: center.color,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          text: center.workingHours,
                          color: center.color,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.phone_rounded,
                          text: center.phone,
                          color: center.color,
                          onTap: () => _makePhoneCall(center.phone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Services ──
                    _DetailBlock(
                      title: 'الخدمات المتوفرة',
                      icon: Icons.medical_services_rounded,
                      color: center.color,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: center.services.map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    center.color.withValues(alpha: 0.12),
                                    center.color.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: center.color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: center.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    service,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: center.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Features ──
                    _DetailBlock(
                      title: 'المميزات',
                      icon: Icons.star_rounded,
                      color: Colors.amber.shade700,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: center.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.withValues(alpha: 0.15),
                                    Colors.orange.withValues(alpha: 0.07),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Call button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(center.phone),
                        icon: const Icon(Icons.phone_rounded, size: 22),
                        label: const Text(
                          'اتصل الآن',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: center.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: center.color.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.14),
                  color.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
                decoration:
                    onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_left_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}

// ====== صفحة إضافة مركز أشعة ======
class _AddRadiologyCenterScreen extends StatefulWidget {
  const _AddRadiologyCenterScreen();

  @override
  State<_AddRadiologyCenterScreen> createState() =>
      _AddRadiologyCenterScreenState();
}

class _AddRadiologyCenterScreenState
    extends State<_AddRadiologyCenterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _facebookController = TextEditingController();
  final _locationController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _featuresController = TextEditingController();
  final _discountsController = TextEditingController();
  final _contractsController = TextEditingController();

  bool _hasBooking = false;

  static const _availableServices = [
    'أشعة عادية (X-Ray)',
    'أشعة مقطعية (CT Scan)',
    'رنين مغناطيسي (MRI)',
    'موجات صوتية (Ultrasound)',
    'ماموجرام',
    'دوبلر وعائي',
    'أشعة بانوراما للأسنان',
    'قسطرة قلبية',
  ];

  final Set<String> _selectedServices = {};

  bool _isOpen24Hours = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _locationController.dispose();
    _workingHoursController.dispose();
    _featuresController.dispose();
    _discountsController.dispose();
    _contractsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار خدمة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // هنا يمكن إرسال البيانات إلى قاعدة البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال البيانات بنجاح وسيتم مراجعتها'),
        backgroundColor: Color(0xFF9C27B0),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة مركز أشعة',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF9C27B0),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- بطاقة المعلومات الأساسية ---
              _SectionCard(
                title: 'المعلومات الأساسية',
                icon: Icons.info_outline,
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'اسم المركز',
                    hint: 'مثال: مركز الفيوم للأشعة',
                    icon: Icons.medical_information,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _addressController,
                    label: 'العنوان التفصيلي',
                    hint: 'الشارع، الحي، المنطقة',
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    hint: '010xxxxxxxx',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      if (!RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(v.trim())) {
                        return 'رقم هاتف غير صحيح';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- بطاقة التواصل الرقمي ---
              _SectionCard(
                title: 'التواصل الرقمي',
                icon: Icons.share,
                children: [
                  _buildField(
                    controller: _whatsappController,
                    label: 'رقم واتساب',
                    hint: '010xxxxxxxx',
                    icon: Icons.chat,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _facebookController,
                    label: 'رابط صفحة فيس بوك',
                    hint: 'https://facebook.com/...',
                    icon: Icons.facebook,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _locationController,
                    label: 'رابط الموقع الجغرافي',
                    hint: 'https://maps.google.com/...',
                    icon: Icons.map,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- بطاقة ساعات العمل ---
              _SectionCard(
                title: 'ساعات العمل',
                icon: Icons.access_time,
                children: [
                  SwitchListTile(
                    value: _isOpen24Hours,
                    onChanged: (val) => setState(() {
                      _isOpen24Hours = val;
                      if (val) {
                        _workingHoursController.text = 'يعمل 24 ساعة';
                      } else {
                        _workingHoursController.clear();
                      }
                    }),
                    title: const Text('يعمل 24 ساعة'),
                    activeColor: const Color(0xFF9C27B0),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!_isOpen24Hours) ...[
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _workingHoursController,
                      label: 'ساعات العمل',
                      hint: 'مثال: 8 ص - 10 م يومياً',
                      icon: Icons.access_time_filled,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // --- بطاقة الخدمات ---
              _SectionCard(
                title: 'الخدمات المتوفرة',
                icon: Icons.check_circle_outline,
                children: [
                  const Text(
                    'اختر الخدمات التي يقدمها المركز',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ..._availableServices.map((service) {
                    final selected = _selectedServices.contains(service);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (val) => setState(() {
                        if (val == true) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      }),
                      title: Text(service, style: const TextStyle(fontSize: 14)),
                      activeColor: const Color(0xFF9C27B0),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // --- بطاقة المميزات ---
              _SectionCard(
                title: 'مميزات المركز',
                icon: Icons.star_outline,
                children: [
                  _buildField(
                    controller: _featuresController,
                    label: 'المميزات',
                    hint: 'مثال: أحدث الأجهزة، نتائج فورية...',
                    icon: Icons.star,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'افصل بين كل ميزة بفاصلة (،)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- بطاقة الخصومات والتعاقدات ---
              _SectionCard(
                title: 'الخصومات والتعاقدات',
                icon: Icons.local_offer,
                children: [
                  _buildField(
                    controller: _discountsController,
                    label: 'الخصومات المتاحة',
                    hint: 'مثال: خصم 15% للمتقاعدين، خصم 10% للطلاب...',
                    icon: Icons.discount,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'افصل بين كل خصم بفاصلة (،)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _contractsController,
                    label: 'التعاقدات',
                    hint: 'مثال: تعاقد مع شركات التأمين، هيئة الصحة...',
                    icon: Icons.handshake,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'افصل بين كل تعاقد بفاصلة (،)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- بطاقة الحجز ---
              _SectionCard(
                title: 'حجز الخدمة',
                icon: Icons.calendar_today,
                children: [
                  SwitchListTile(
                    value: _hasBooking,
                    onChanged: (val) => setState(() => _hasBooking = val),
                    title: const Text('يتوفر نظام حجز مسبق'),
                    subtitle: const Text(
                      'تفعيل إذا كان المركز يقبل الحجز المسبق عبر الهاتف أو التطبيق',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: const Color(0xFF9C27B0),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- زر الإرسال ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'إرسال البيانات',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF9C27B0), size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9C27B0).withValues(alpha: 0.14),
                    const Color(0xFF9C27B0).withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF9C27B0),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
