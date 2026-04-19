import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/doctor_specialties.dart';
import '../deep_link_config.dart';
import '../services/medical_centers_media_service.dart';
import '../widgets/medical_center_reviews_widget.dart';

class MedicalCentersScreen extends StatefulWidget {
  const MedicalCentersScreen({super.key, this.initialCenterName});

  final String? initialCenterName;

  @override
  State<MedicalCentersScreen> createState() => _MedicalCentersScreenState();
}

class _MedicalCentersScreenState extends State<MedicalCentersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoadingFromDb = false;

  final List<String> _serviceFilters = const [
    'عيادات متعددة',
    'عيادات طوارئ',
    'معمل تحاليل',
    'أشعة',
    'يعمل 24 ساعة',
  ];

  final Set<String> _selectedServices = <String>{};

  final List<_MedicalCenter> _allCenters = <_MedicalCenter>[];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _loadPublishedCenters();

    final initial = widget.initialCenterName?.trim();
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openCenterFromInitialName(initial);
      });
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return const <String>[];
  }

  List<Map<String, String>> _doctorsList(dynamic value) {
    if (value is! List) return const <Map<String, String>>[];
    final result = <Map<String, String>>[];
    for (final item in value) {
      if (item is Map) {
        final name = (item['name'] ?? '').toString();
        final title = (item['title'] ?? '').toString();
        final photoUrl = (item['photo_url'] ?? '').toString();
        if (name.trim().isEmpty) continue;
        result.add({
          'name': name,
          'title': title,
          if (photoUrl.trim().isNotEmpty) 'photo_url': photoUrl,
        });
      }
    }
    return result;
  }

  Future<void> _loadPublishedCenters() async {
    if (!mounted) return;
    setState(() => _isLoadingFromDb = true);

    try {
      final rows = await Supabase.instance.client
          .from('medical_centers')
          .select(
            'id,name,address,phone,whatsapp,working_hours,geo_location,facebook_page,cover_image_url,gallery_image_urls,available_contracts,offers_and_discounts,has_booking,booking_methods,booking_url,booking_notes,booking_patients_per_hour,specialties,services,features,doctors,rating,rating_count,created_at',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final centers = <_MedicalCenter>[];
      for (final r in rows) {
        centers.add(_mapDbRowToMedicalCenter(Map<String, dynamic>.from(r)));
      }

      if (!mounted) return;
      setState(() {
        _allCenters
          ..clear()
          ..addAll(centers);
        _isLoadingFromDb = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFromDb = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل المراكز الطبية من الخادم.')),
      );
    }
  }

  Future<void> _openCenterFromInitialName(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;

    final match = _allCenters.cast<_MedicalCenter?>().firstWhere(
      (c) => c != null && c.name.trim() == normalized,
      orElse: () => null,
    );

    if (match != null) {
      _openDetails(match);
      return;
    }

    _MedicalCenter? fetched;
    try {
      fetched = await _fetchPublishedCenterByName(normalized);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل بيانات المركز من الخادم.')),
      );
      return;
    }
    if (!mounted) return;
    if (fetched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على المركز المطلوب.')),
      );
      return;
    }

    final fetchedCenter = fetched;

    setState(() {
      _allCenters.insert(0, fetchedCenter);
    });
    _openDetails(fetchedCenter);
  }

  _MedicalCenter _mapDbRowToMedicalCenter(Map<String, dynamic> row) {
    final gallery = _stringList(row['gallery_image_urls']);
    final specialties = _stringList(row['specialties']);
    final services = _stringList(row['services']);
    final features = _stringList(row['features']);
    final bookingMethods = _stringList(row['booking_methods']);
    final doctors = _doctorsList(row['doctors']);

    return _MedicalCenter(
      id: (row['id'] ?? '').toString().trim(),
      name: (row['name'] as String?)?.trim() ?? 'مركز طبي',
      address: (row['address'] as String?)?.trim() ?? '',
      phone: (row['phone'] as String?)?.trim() ?? '',
      whatsappNumber: (row['whatsapp'] as String?)?.trim(),
      doctors: doctors,
      rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
      workingHours: (row['working_hours'] as String?)?.trim() ?? 'غير محدد',
      specialties: specialties,
      services: services,
      features: features,
      geoLocation: (row['geo_location'] as String?)?.trim(),
      facebookPage: (row['facebook_page'] as String?)?.trim(),
      coverImageUrl: (row['cover_image_url'] as String?)?.trim(),
      galleryImageUrls: gallery,
      availableContracts: (row['available_contracts'] as String?)?.trim(),
      offersAndDiscounts: (row['offers_and_discounts'] as String?)?.trim(),
      bookingEnabled: row['has_booking'] == true,
      bookingMethods: bookingMethods,
      bookingPatientsPerHour: row['booking_patients_per_hour'] is int
          ? row['booking_patients_per_hour'] as int
          : null,
      bookingUrl: (row['booking_url'] as String?)?.trim(),
      bookingNotes: (row['booking_notes'] as String?)?.trim(),
      icon: Icons.medical_services,
      color: const Color(0xFF00BCD4),
    );
  }

  Future<_MedicalCenter?> _fetchPublishedCenterByName(String name) async {
    final rows = await Supabase.instance.client
        .from('medical_centers')
        .select(
          'id,name,address,phone,whatsapp,working_hours,geo_location,facebook_page,cover_image_url,gallery_image_urls,available_contracts,offers_and_discounts,has_booking,booking_methods,booking_url,booking_notes,booking_patients_per_hour,specialties,services,features,doctors,rating,rating_count',
        )
        .eq('is_published', true)
        .eq('name', name)
        .limit(1);

    if (rows.isEmpty) return null;
    return _mapDbRowToMedicalCenter(Map<String, dynamic>.from(rows.first));
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ بيانات المركز وإرسال طلب النشر للمدير.'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    _openDetails(newCenter);
  }

  Future<void> _openOwnerLoginThenAddCenter() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _MedicalCenterOwnerLoginScreen()),
    );
    if (!mounted) return;
    if (ok != true) return;
    await _openAddCenter();
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
                    tooltip: 'تسجيل دخول مركز طبي',
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/med.center.PNG',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onPressed: _openOwnerLoginThenAddCenter,
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
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: 0.22,
                            child: Image.asset(
                              'assets/images/med.center.PNG',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
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
                              child: Image.asset(
                                'assets/images/med.center.PNG',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
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

              if (_isLoadingFromDb)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
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
                                  _allCenters.isEmpty
                                      ? 'لا توجد مراكز طبية بعد'
                                      : 'لا توجد مراكز مطابقة للفلاتر المحددة',
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

class _MedicalCenterOwnerLoginScreen extends StatefulWidget {
  const _MedicalCenterOwnerLoginScreen();

  @override
  State<_MedicalCenterOwnerLoginScreen> createState() =>
      _MedicalCenterOwnerLoginScreenState();
}

class _MedicalCenterOwnerLoginScreenState
    extends State<_MedicalCenterOwnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _login() async {
    if (_loading) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final auth = Supabase.instance.client.auth;
      final res = await auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = res.user;
      if (user == null) {
        _showSnack('تعذر تسجيل الدخول. حاول مرة أخرى.');
        return;
      }

      final meta = user.userMetadata ?? const <String, dynamic>{};
      final userType = meta['user_type']?.toString();
      if (userType != 'medical_center') {
        await auth.signOut();
        _showSnack('هذا الحساب ليس حساب مركز طبي.', color: Colors.orange);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      _showSnack(e.message, color: Colors.red);
    } catch (_) {
      _showSnack('حدث خطأ غير متوقع أثناء تسجيل الدخول.', color: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل دخول المركز الطبي'),
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/med.center.PNG',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'استخدم بيانات الدخول التي أنشأها المدير',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'أدخل البريد الإلكتروني';
                            if (!value.contains('@')) {
                              return 'أدخل بريد إلكتروني صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _obscure = !_obscure);
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if ((v ?? '').isEmpty) {
                              return 'أدخل كلمة المرور';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4),
                              foregroundColor: Colors.white,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}

class _MedicalCenter {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? whatsappNumber;
  final List<Map<String, String>> doctors;
  final bool bookingEnabled;
  final List<String> bookingMethods;
  final int? bookingPatientsPerHour;
  final int? bookingSlotMinutes;
  final String? bookingUrl;
  final String? bookingNotes;
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
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.whatsappNumber,
    this.doctors = const <Map<String, String>>[],
    this.bookingEnabled = false,
    this.bookingMethods = const <String>[],
    this.bookingPatientsPerHour,
    this.bookingSlotMinutes,
    this.bookingUrl,
    this.bookingNotes,
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: center.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/med.center.PNG',
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
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

class _MedicalCenterDetailsScreen extends StatefulWidget {
  const _MedicalCenterDetailsScreen({required this.center});

  final _MedicalCenter center;

  @override
  State<_MedicalCenterDetailsScreen> createState() =>
      _MedicalCenterDetailsScreenState();
}

class _MedicalCenterDetailsScreenState
    extends State<_MedicalCenterDetailsScreen> {
  final GlobalKey _qrKey = GlobalKey();
  late double _rating;
  late int _ratingCount;

  @override
  void initState() {
    super.initState();
    _rating = widget.center.rating;
    _ratingCount = widget.center.ratingCount;
  }

  Widget _contactIconChip({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isFa = icon.fontPackage == 'font_awesome_flutter';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: isFa
                  ? FaIcon(icon, color: color, size: 30)
                  : Icon(icon, color: color, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  void _showDoctorDetailsDialog(Map<String, String> doc, Color accentColor) {
    final name = (doc['name'] ?? '').trim();
    final title = (doc['title'] ?? '').trim();
    final photoUrl = (doc['photo_url'] ?? '').trim();

    final extra = doc.entries
        .where(
          (e) =>
              e.key != 'name' &&
              e.key != 'title' &&
              e.key != 'photo_url' &&
              e.value.trim().isNotEmpty,
        )
        .toList();

    String labelForKey(String key) {
      switch (key) {
        case 'specialty':
          return 'التخصص';
        case 'phone':
          return 'الهاتف';
        case 'whatsapp':
          return 'واتساب';
        case 'email':
          return 'البريد الإلكتروني';
        case 'bio':
          return 'نبذة';
        default:
          return key;
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'بيانات الطبيب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'إغلاق',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _doctorAvatar(name, accentColor),
                                ),
                              )
                            : _doctorAvatar(name, accentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'طبيب' : name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (title.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (extra.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 10),
                      ...extra.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  labelForKey(e.key),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _centerShareLink() {
    return buildPublicMedicalCenterUrl(
      centerName: widget.center.name,
    ).toString();
  }

  Future<Uint8List?> _captureQrPng() async {
    final boundary = _qrKey.currentContext?.findRenderObject();
    if (boundary == null) return null;
    try {
      final image = await (boundary as dynamic).toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _showShareSheet() {
    final link = _centerShareLink();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final qrSize = (width * 0.78).clamp(260.0, 420.0);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'كود QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: link,
                        size: qrSize,
                        backgroundColor: Colors.white,
                        version: QrVersions.auto,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'اضغط مشاركة لإرسال الكود أو الرابط.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final bytes = await _captureQrPng();
                        if (!context.mounted) return;

                        if (bytes == null) {
                          await Share.share(link);
                          return;
                        }

                        await Share.shareXFiles([
                          XFile.fromData(
                            bytes,
                            name: 'medical_center_qr.png',
                            mimeType: 'image/png',
                          ),
                        ], text: 'صفحة المركز الطبي: $link');
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تطبيق الاتصال على هذا الجهاز.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _sanitizeLinkString(String raw) {
    // إزالة علامات الاتجاه (RTL/LTR) ومسافات غير مرئية قد تكسر فتح الروابط.
    final cleaned = raw
        .replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'), '')
        .trim();
    // إزالة أي مسافات/أسطر داخل الرابط نفسه.
    return cleaned.replaceAll(RegExp(r'\s+'), '');
  }

  String _normalizeUrl(String raw) {
    final cleaned = _sanitizeLinkString(raw);
    if (cleaned.isEmpty) return cleaned;
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return cleaned;
    if (uri.hasScheme) return cleaned;
    return 'https://$cleaned';
  }

  Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }

  Future<void> _openUrl(String url) async {
    final cleaned = _normalizeUrl(url);
    if (cleaned.isEmpty) return;
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return;

    if (await _tryLaunch(uri, LaunchMode.externalApplication)) return;
    if (await _tryLaunch(uri, LaunchMode.platformDefault)) return;
    if (await _tryLaunch(uri, LaunchMode.inAppBrowserView)) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعذر فتح الرابط على هذا الجهاز.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = _sanitizeLinkString(phone);
    if (cleaned.isEmpty) return;

    final parsed = Uri.tryParse(cleaned);
    if (parsed != null && parsed.hasScheme) {
      await _openUrl(cleaned);
      return;
    }

    // رقم فقط
    var digits = _digitsOnly(cleaned);
    if (digits.isEmpty) return;

    // تحسين للأرقام المصرية الشائعة: 01XXXXXXXXX -> 20 + 1XXXXXXXXX
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '20${digits.substring(1)}';
    }

    // جرّب فتح تطبيق واتساب مباشرة أولاً
    final appUri = Uri.parse('whatsapp://send?phone=$digits');
    final appLaunched = await _tryLaunch(
      appUri,
      LaunchMode.externalApplication,
    );
    if (appLaunched) return;

    // fallback: افتح رابط wa.me (يفتح المتصفح/واتساب)
    final webUri = Uri.parse('https://wa.me/$digits');
    if (await _tryLaunch(webUri, LaunchMode.externalApplication)) return;
    if (await _tryLaunch(webUri, LaunchMode.platformDefault)) return;
    if (await _tryLaunch(webUri, LaunchMode.inAppBrowserView)) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعذر فتح واتساب على هذا الجهاز.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _openGeoLocation(String geo) async {
    final cleaned = _sanitizeLinkString(geo);
    if (cleaned.isEmpty) return;

    // لو المستخدم أدخل رابط خرائط كامل، افتحه كما هو.
    final parsed = Uri.tryParse(cleaned);
    if (parsed != null && parsed.hasScheme) {
      await _openUrl(cleaned);
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleaned)}',
    );
    await _openUrl(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center;
    final shareLink = _centerShareLink();
    final accentColor = center.color;
    final hasCover =
        center.coverImageUrl != null && center.coverImageUrl!.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        bottomNavigationBar: _buildFixedBookingBar(center, accentColor),
        body: CustomScrollView(
          slivers: [
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // Hero Header
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            SliverAppBar(
              expandedHeight: hasCover ? 300 : 240,
              pinned: true,
              stretch: true,
              backgroundColor: accentColor,
              leading: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'رجوع',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: IconButton(
                      tooltip: 'مشاركة',
                      onPressed: _showShareSheet,
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
                title: Text(
                  center.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // الخلفية
                    hasCover
                        ? Image.network(
                            center.coverImageUrl!.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _defaultBg(accentColor),
                          )
                        : _defaultBg(accentColor),
                    // تدرج داكن من الأسفل
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // بطاقة الهوية السريعة
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  _buildIdentityCard(center, accentColor, shareLink),

                  const SizedBox(height: 12),

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // أطباء المركز (في الأعلى)
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.doctors.isNotEmpty) ...[
                    _buildDoctorsSection(center, accentColor),
                    const SizedBox(height: 12),
                  ],

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // معرض الصور (إن وجد)
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.galleryImageUrls.isNotEmpty) ...[
                    _buildGallery(center, accentColor),
                    const SizedBox(height: 12),
                  ],

                  // (تم عرض وسائل التواصل كأيقونات فقط داخل بطاقة الهوية بالأعلى)

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // التخصصات
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.specialties.isNotEmpty) ...[
                    _buildHighlightedSpecialtiesBox(
                      center.specialties,
                      accentColor,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // الخدمات
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.services.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'الخدمات المقدمة',
                      icon: Icons.star_half_rounded,
                      accentColor: const Color(0xFFE91E63),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: center.services
                              .where((s) => s.trim().isNotEmpty)
                              .map((service) {
                            const serviceColor = Color(0xFFE91E63);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    serviceColor.withValues(alpha: 0.10),
                                    serviceColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: serviceColor.withValues(alpha: 0.30),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: serviceColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      service.trim(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // المميزات
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.features.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'مميزات المركز',
                      icon: Icons.workspace_premium_rounded,
                      accentColor: const Color(0xFF10B981),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: center.features.map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    f,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // التعاقدات
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.availableContracts?.trim().isNotEmpty == true) ...[
                    _buildSectionCard(
                      title: 'التعاقدات المتاحة',
                      icon: Icons.handshake_rounded,
                      accentColor: const Color(0xFF6366F1),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            center.availableContracts!.trim(),
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // العروض والخصومات
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  if (center.offersAndDiscounts?.trim().isNotEmpty == true) ...[
                    _buildOffersCard(center),
                    const SizedBox(height: 12),
                  ],

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // التقييمات والمراجعات
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: MedicalCenterReviewsSection(
                      centerId: center.id,
                      accentColor: accentColor,
                      currentRating: _rating,
                      ratingCount: _ratingCount,
                      onSummaryChanged: (summary) {
                        setState(() {
                          if (summary.rating != null) {
                            _rating = summary.rating!;
                          }
                          if (summary.ratingCount != null) {
                            _ratingCount = summary.ratingCount!;
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  // QR Code
                  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                  _buildQrCard(shareLink, accentColor),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final nextLightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(nextLightness).toColor();
  }

  Widget _buildFixedBookingBar(_MedicalCenter center, Color accentColor) {
    final isEnabled = center.bookingEnabled;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled
                ? () => _showCenterBookingSheet(center, accentColor)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isEnabled
                    ? LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          accentColor,
                          _darken(accentColor, 0.18),
                        ],
                      )
                    : null,
                color: isEnabled ? null : Colors.grey.shade400,
                boxShadow: [
                  BoxShadow(
                    color: isEnabled
                        ? accentColor.withValues(alpha: 0.30)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      isEnabled ? Icons.event_available : Icons.event_busy,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEnabled ? 'احجز الآن' : 'الحجز غير متاح حالياً',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isEnabled
                              ? 'اختر طريقة الحجز المناسبة'
                              : 'جرّب التواصل هاتفياً أو واتساب',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEnabled)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.95),
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

  Future<void> _showCenterBookingSheet(
    _MedicalCenter center,
    Color accentColor,
  ) async {
    final methods = center.bookingMethods;
    final hasPhone = center.phone.trim().isNotEmpty;
    final hasWhatsApp = center.whatsappNumber?.trim().isNotEmpty == true;
    final hasUrl = center.bookingUrl?.trim().isNotEmpty == true;
    final notes = center.bookingNotes?.trim() ?? '';

    final showCall = methods.contains('اتصال هاتفي') && hasPhone;
    final showWhatsApp = methods.contains('واتساب') && hasWhatsApp;
    final showUrl = methods.contains('رابط خارجي') && hasUrl;
    final showInApp = methods.contains('داخل التطبيق (قريباً)');

    if (!showCall && !showWhatsApp && !showUrl && !showInApp) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد طرق حجز مضافة لهذا المركز حالياً.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الحجز في ${center.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  if (center.bookingPatientsPerHour != null &&
                      center.bookingPatientsPerHour! > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'السعة: ${center.bookingPatientsPerHour} مريض/ساعة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notes,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  if (showCall)
                    ListTile(
                      leading: const Icon(Icons.phone_rounded),
                      title: const Text('اتصال هاتفي'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _makePhoneCall(center.phone);
                      },
                    ),
                  if (showWhatsApp)
                    ListTile(
                      leading: const Icon(Icons.chat_rounded),
                      title: const Text('واتساب'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _openWhatsApp(center.whatsappNumber!);
                      },
                    ),
                  if (showUrl)
                    ListTile(
                      leading: const Icon(Icons.link_rounded),
                      title: const Text('الحجز عبر الرابط'),
                      subtitle: Text(
                        center.bookingUrl!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _openUrl(center.bookingUrl!.trim());
                      },
                    ),
                  if (showInApp)
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('داخل التطبيق (قريباً)'),
                      subtitle: const Text('سيتم تفعيلها قريباً'),
                      enabled: false,
                    ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── خلفية افتراضية ──
  Widget _defaultBg(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.22,
          child: Image.asset(
            'assets/images/med.center.PNG',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ── بطاقة الهوية السريعة ──
  Widget _buildIdentityCard(
    _MedicalCenter center,
    Color accentColor,
    String shareLink,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // أيقونة المركز
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/med.center.PNG',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            center.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // بطاقة المواعيد (مميّزة وأطول)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المواعيد',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        center.workingHours.trim().isEmpty
                            ? 'غير متوفر'
                            : center.workingHours.split('\n').first,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: Color(0xFF4C1D95),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // (أيقونات فقط) في صف واحد تحت ساعات العمل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (center.geoLocation?.isNotEmpty == true)
                _contactIconChip(
                  icon: FontAwesomeIcons.locationDot,
                  color: const Color(0xFFEF4444),
                  tooltip: 'الموقع على الخرائط',
                  onTap: () => _openGeoLocation(center.geoLocation!),
                ),
              if (center.facebookPage?.isNotEmpty == true)
                _contactIconChip(
                  icon: Icons.facebook_rounded,
                  color: const Color(0xFF1877F2),
                  tooltip: 'صفحة فيسبوك',
                  onTap: () => _openUrl(center.facebookPage!),
                ),
              _contactIconChip(
                icon: Icons.phone_rounded,
                color: const Color(0xFF10B981),
                tooltip: 'اتصال هاتفي',
                onTap: () => _makePhoneCall(center.phone),
              ),
              if (center.whatsappNumber?.isNotEmpty == true)
                _contactIconChip(
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                  tooltip: 'واتساب',
                  onTap: () => _openWhatsApp(center.whatsappNumber!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── معرض الصور ──
  Widget _buildGallery(_MedicalCenter center, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'معرض الصور',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${center.galleryImageUrls.length} صورة',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: center.galleryImageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final url = center.galleryImageUrls[i];
                return GestureDetector(
                  onTap: () => _showImageDialog(context, url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ── قسم منظم ──
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  accentColor.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildHighlightedSpecialtiesBox(
    List<String> specialties,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accentColor.withValues(alpha: 0.10),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/med.center.PNG',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'التخصصات المتوفرة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    '${specialties.length} تخصص',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: accentColor.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: specialties.map((s) {
                final icon = _specialtyIcon(s);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        s,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── قسم الأطباء ──
  Widget _buildDoctorsSection(_MedicalCenter center, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'أطباء المركز',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    '${center.doctors.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: center.doctors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.30,
              ),
              itemBuilder: (context, index) {
                final doc = center.doctors[index];
                final name = (doc['name'] ?? '').trim();
                final photoUrl = (doc['photo_url'] ?? '').trim();

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDoctorDetailsDialog(doc, accentColor),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          photoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _doctorAvatar(name, accentColor),
                                  ),
                                )
                              : _doctorAvatar(name, accentColor),
                          const SizedBox(height: 10),
                          Text(
                            name.isEmpty ? 'طبيب' : name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorAvatar(String name, Color color) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        name.isNotEmpty ? name[0] : 'د',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── بطاقة العروض ──
  Widget _buildOffersCard(_MedicalCenter center) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'عروض وخصومات',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  center.offersAndDiscounts!.trim(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── بطاقة QR ──
  Widget _buildQrCard(String shareLink, Color accentColor) {
    return GestureDetector(
      onTap: _showShareSheet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: QrImageView(
                data: shareLink,
                backgroundColor: Colors.white,
                version: QrVersions.auto,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'شارك المركز',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'امسح الكود أو اضغط لمشاركة الرابط',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.share_rounded, color: accentColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  IconData _specialtyIcon(String specialty) {
    if (specialty.contains('قلب')) {
      return Icons.favorite_rounded;
    }
    if (specialty.contains('عظام') || specialty.contains('مفاصل')) {
      return Icons.accessibility_new_rounded;
    }
    if (specialty.contains('أطفال') || specialty.contains('اطفال')) {
      return Icons.child_care_rounded;
    }
    if (specialty.contains('نساء') || specialty.contains('ولادة')) {
      return Icons.pregnant_woman_rounded;
    }
    if (specialty.contains('عيون') || specialty.contains('بصريات')) {
      return Icons.remove_red_eye_rounded;
    }
    if (specialty.contains('أسنان') || specialty.contains('اسنان')) {
      return Icons.sentiment_satisfied_rounded;
    }
    if (specialty.contains('جلد') || specialty.contains('تجميل')) {
      return Icons.spa_rounded;
    }
    if (specialty.contains('أشعة') || specialty.contains('اشعة')) {
      return Icons.biotech_rounded;
    }
    if (specialty.contains('تحاليل') || specialty.contains('مختبر')) {
      return Icons.science_rounded;
    }
    if (specialty.contains('طوارئ')) {
      return Icons.emergency_rounded;
    }
    if (specialty.contains('باطنة') || specialty.contains('داخلية')) {
      return Icons.medical_services_rounded;
    }
    if (specialty.contains('نفس') || specialty.contains('أعصاب')) {
      return Icons.psychology_rounded;
    }
    return Icons.local_hospital_rounded;
  }
}

class _AddMedicalCenterScreen extends StatefulWidget {
  const _AddMedicalCenterScreen();

  @override
  State<_AddMedicalCenterScreen> createState() =>
      _AddMedicalCenterScreenState();
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

  // Doctors
  final List<_MedicalCenterDoctorEntry> _doctors =
      <_MedicalCenterDoctorEntry>[];
  int? _uploadingDoctorIndex;

  // Booking settings
  bool _bookingEnabled = false;
  final Set<String> _bookingMethods = <String>{};
  int _bookingPatientsPerHour = 4;
  final _bookingUrlController = TextEditingController();
  final _bookingNotesController = TextEditingController();

  bool _submitting = false;
  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;
  bool _loadingExistingCenter = false;
  String? _existingCenterId;

  int _activeCenterSection = 0; // 0: بيانات المركز، 1: إدارة طلبات الحجز

  final Set<String> _selectedSpecialties = <String>{};
  final Set<String> _selectedFeatures = <String>{};
  final Set<String> _selectedServices = <String>{};
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

  static const List<String> _bookingMethodOptions = <String>[
    'اتصال هاتفي',
    'واتساب',
    'رابط خارجي',
    'داخل التطبيق (قريباً)',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onMediaChanged);
    _addressController.addListener(_onMediaChanged);
    _phoneController.addListener(_onMediaChanged);
    _workingHoursController.addListener(_onMediaChanged);
    _coverImageController.addListener(_onMediaChanged);
    _galleryController.addListener(_onMediaChanged);

    _loadExistingCenterForCurrentUser();
  }

  List<String> _stringListFromDb(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return const <String>[];
  }

  List<Map<String, String>> _doctorsListFromDb(dynamic value) {
    if (value is! List) return const <Map<String, String>>[];
    final result = <Map<String, String>>[];
    for (final item in value) {
      if (item is Map) {
        final name = (item['name'] ?? '').toString();
        if (name.trim().isEmpty) continue;
        result.add({
          'name': name,
          'title': (item['title'] ?? '').toString(),
          'photo_url': (item['photo_url'] ?? '').toString(),
        });
      }
    }
    return result;
  }

  Future<void> _loadExistingCenterForCurrentUser() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _loadingExistingCenter = true);

    try {
      final rows = await client
          .from('medical_centers')
          .select(
            'id,name,address,phone,whatsapp,working_hours,geo_location,facebook_page,cover_image_url,gallery_image_urls,available_contracts,offers_and_discounts,has_booking,booking_methods,booking_url,booking_notes,booking_patients_per_hour,specialties,services,features,doctors,is_published,publish_requested,created_at',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() {
          _existingCenterId = null;
          _loadingExistingCenter = false;
        });
        return;
      }

      final row = Map<String, dynamic>.from(rows.first);
      final existingId = (row['id'] ?? '').toString().trim();
      if (existingId.isEmpty) {
        setState(() => _loadingExistingCenter = false);
        return;
      }

      final specialties = _stringListFromDb(row['specialties']);
      final services = _stringListFromDb(row['services']);
      final features = _stringListFromDb(row['features']);
      final bookingMethods = _stringListFromDb(row['booking_methods']);
      final galleryUrls = _stringListFromDb(row['gallery_image_urls']);
      final doctors = _doctorsListFromDb(row['doctors']);

      setState(() {
        _existingCenterId = existingId;

        _nameController.text = (row['name'] as String?)?.trim() ?? '';
        _addressController.text = (row['address'] as String?)?.trim() ?? '';
        _phoneController.text = (row['phone'] as String?)?.trim() ?? '';
        _whatsappController.text = (row['whatsapp'] as String?)?.trim() ?? '';
        _workingHoursController.text =
            (row['working_hours'] as String?)?.trim() ?? '';
        _geoLocationController.text =
            (row['geo_location'] as String?)?.trim() ?? '';
        _facebookController.text =
            (row['facebook_page'] as String?)?.trim() ?? '';
        _coverImageController.text =
            (row['cover_image_url'] as String?)?.trim() ?? '';
        _galleryController.text = galleryUrls.join('\n');
        _contractsController.text =
            (row['available_contracts'] as String?)?.trim() ?? '';
        _offersController.text =
            (row['offers_and_discounts'] as String?)?.trim() ?? '';

        _selectedSpecialties
          ..clear()
          ..addAll(specialties);
        _selectedServices
          ..clear()
          ..addAll(services);
        _selectedFeatures
          ..clear()
          ..addAll(features);

        _bookingEnabled = row['has_booking'] == true;
        _bookingMethods
          ..clear()
          ..addAll(bookingMethods);
        _bookingPatientsPerHour = row['booking_patients_per_hour'] is int
            ? row['booking_patients_per_hour'] as int
            : _bookingPatientsPerHour;
        _bookingUrlController.text =
            (row['booking_url'] as String?)?.trim() ?? '';
        _bookingNotesController.text =
            (row['booking_notes'] as String?)?.trim() ?? '';

        for (final d in _doctors) {
          d.dispose();
        }
        _doctors.clear();
        for (final d in doctors) {
          final entry = _MedicalCenterDoctorEntry();
          entry.nameController.text = (d['name'] ?? '').trim();
          entry.titleController.text = (d['title'] ?? '').trim();
          final photoUrl = (d['photo_url'] ?? '').trim();
          if (photoUrl.isNotEmpty) {
            entry.photoUrlController.text = photoUrl;
          }
          _doctors.add(entry);
        }

        // لتجديد Dropdowns.
        _specialtyPickerKeySeed++;
        _featurePickerKeySeed++;

        _loadingExistingCenter = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingExistingCenter = false);
    }
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

  void _addServicesFromInput() {
    final items = _splitList(_servicesController.text);
    if (items.isEmpty) return;
    setState(() {
      _selectedServices.addAll(items);
      _servicesController.clear();
    });
  }

  void _removeService(String value) {
    setState(() {
      _selectedServices.remove(value);
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
    _bookingUrlController.dispose();
    _bookingNotesController.dispose();
    for (final d in _doctors) {
      d.dispose();
    }
    super.dispose();
  }

  void _addDoctor() {
    setState(() => _doctors.add(_MedicalCenterDoctorEntry()));
  }

  void _removeDoctor(int index) {
    _doctors[index].dispose();
    setState(() => _doctors.removeAt(index));
  }

  Future<void> _pickAndUploadDoctorPhoto(int index) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() => _uploadingDoctorIndex = index);

      final url = await _mediaService.uploadImage(picked, 'doctors');
      if (!mounted) return;
      setState(() {
        _doctors[index].photoUrlController.text = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفع صورة الطبيب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع صورة الطبيب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingDoctorIndex = null);
    }
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
        SnackBar(
          content: Text('خطأ في رفع صورة الكفر: $e'),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text('خطأ في رفع صور المعرض: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // لو المستخدم كتب خدمات ولم يضغط (+) نضيفها تلقائياً.
    _selectedServices.addAll(_splitList(_servicesController.text));

    if (_bookingEnabled && _bookingMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار طريقة حجز واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_bookingEnabled &&
        _bookingMethods.contains('رابط خارجي') &&
        _bookingUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رابط الحجز (لأن طريقة الحجز: رابط خارجي)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final doctorsList = <Map<String, String>>[];
    for (final d in _doctors) {
      final name = d.nameController.text.trim();
      final title = d.titleController.text.trim();
      final photoUrl = d.photoUrlController.text.trim();
      if (name.isEmpty) continue;
      doctorsList.add({
        'name': name,
        'title': title,
        if (photoUrl.isNotEmpty) 'photo_url': photoUrl,
      });
    }

    final center = _MedicalCenter(
      id: _existingCenterId ?? '',
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      whatsappNumber: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      doctors: doctorsList,
      bookingEnabled: _bookingEnabled,
      bookingMethods: _bookingMethods.toList(),
      bookingPatientsPerHour: _bookingEnabled ? _bookingPatientsPerHour : null,
      bookingSlotMinutes: null,
      bookingUrl:
          (_bookingEnabled && _bookingUrlController.text.trim().isNotEmpty)
          ? _bookingUrlController.text.trim()
          : null,
      bookingNotes:
          (_bookingEnabled && _bookingNotesController.text.trim().isNotEmpty)
          ? _bookingNotesController.text.trim()
          : null,
      rating: 0,
      ratingCount: 0,
      workingHours: _workingHoursController.text.trim(),
      specialties: _selectedSpecialties.toList(),
        services: _selectedServices.toList(),
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

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تسجيل الدخول أولاً لحفظ بيانات المركز.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final payload = <String, dynamic>{
        'user_id': user.id,
        'name': center.name,
        'address': center.address,
        'phone': center.phone,
        'whatsapp': center.whatsappNumber,
        'working_hours': center.workingHours,
        'geo_location': center.geoLocation,
        'facebook_page': center.facebookPage,
        'cover_image_url': center.coverImageUrl,
        'gallery_image_urls': center.galleryImageUrls,
        'available_contracts': center.availableContracts,
        'offers_and_discounts': center.offersAndDiscounts,
        'has_booking': center.bookingEnabled,
        'booking_methods': center.bookingMethods,
        'booking_url': center.bookingUrl,
        'booking_notes': center.bookingNotes,
        'booking_patients_per_hour': center.bookingPatientsPerHour,
        'specialties': center.specialties,
        'services': center.services,
        'features': center.features,
        'doctors': center.doctors,
        'publish_requested': true,
      };

      String? targetId = _existingCenterId;
      if (targetId == null) {
        final existing = await client
            .from('medical_centers')
            .select('id,created_at')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(1);
        if (existing.isNotEmpty) {
          targetId = (existing.first['id'] ?? '').toString().trim();
        }
      }

      if (targetId != null && targetId.isNotEmpty) {
        await client.from('medical_centers').update(payload).eq('id', targetId);
        if (mounted) setState(() => _existingCenterId = targetId);
      } else {
        final dynamic inserted = await client.from('medical_centers').insert({
          ...payload,
          'is_published': false,
        }).select('id');

        if (inserted is List && inserted.isNotEmpty) {
          final first = inserted.first;
          if (first is Map) {
            targetId = (first['id'] ?? '').toString().trim();
          } else {
            targetId = first.toString().trim();
          }
        } else if (inserted is Map) {
          targetId = (inserted['id'] ?? '').toString().trim();
        }
      }

      // جلب التقييم الحالي (إن وُجدت الأعمدة) + ضمان وجود id في الكائن المرجع
      Map<String, dynamic>? savedRow;
      if (targetId != null && targetId.isNotEmpty) {
        try {
          final dynamic rows = await client
              .from('medical_centers')
              .select('id,rating,rating_count')
              .eq('id', targetId)
              .limit(1);

          if (rows is List && rows.isNotEmpty) {
            savedRow = Map<String, dynamic>.from(rows.first as Map);
          }
        } catch (_) {
          savedRow = null;
        }
      }

      final savedCenter = _MedicalCenter(
        id: (savedRow?['id'] ?? targetId ?? center.id).toString(),
        name: center.name,
        address: center.address,
        phone: center.phone,
        whatsappNumber: center.whatsappNumber,
        doctors: center.doctors,
        bookingEnabled: center.bookingEnabled,
        bookingMethods: center.bookingMethods,
        bookingPatientsPerHour: center.bookingPatientsPerHour,
        bookingSlotMinutes: center.bookingSlotMinutes,
        bookingUrl: center.bookingUrl,
        bookingNotes: center.bookingNotes,
        rating: (savedRow?['rating'] as num?)?.toDouble() ?? center.rating,
        ratingCount:
            (savedRow?['rating_count'] as num?)?.toInt() ?? center.ratingCount,
        workingHours: center.workingHours,
        specialties: center.specialties,
        services: center.services,
        features: center.features,
        geoLocation: center.geoLocation,
        facebookPage: center.facebookPage,
        coverImageUrl: center.coverImageUrl,
        galleryImageUrls: center.galleryImageUrls,
        availableContracts: center.availableContracts,
        offersAndDiscounts: center.offersAndDiscounts,
        icon: center.icon,
        color: center.color,
      );

      if (!mounted) return;
      Navigator.pop(context, savedCenter);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ البيانات على الخادم: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع أثناء حفظ بيانات المركز.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryUrls = _splitList(_galleryController.text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _existingCenterId == null ? 'إضافة مركز طبي' : 'تعديل مركز طبي',
          ),
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: _loadingExistingCenter
              ? const Center(child: CircularProgressIndicator())
              : Container(
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
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  'assets/images/med.center.PNG',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeCenterSection == 0
                                      ? 'بيانات المركز الطبي'
                                      : 'إدارة طلبات الحجز',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _activeCenterSection == 0
                                      ? 'املأ البيانات الأساسية ثم أضف الصور والروابط إن وجدت'
                                      : 'تابع الطلبات ووافق/ارفض (سيتم تفعيلها عند ربط قاعدة البيانات)',
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
                        border: Border.all(
                          color: _brandColor.withValues(alpha: 0.10),
                        ),
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
                              backgroundColor: _brandColor.withValues(
                                alpha: 0.12,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _brandColor.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 56,
                        child: SegmentedButton<int>(
                          style: ButtonStyle(
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            textStyle: const WidgetStatePropertyAll(
                              TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            side: WidgetStateProperty.resolveWith((states) {
                              final isSelected = states.contains(
                                WidgetState.selected,
                              );
                              return BorderSide(
                                color: _brandColor.withValues(
                                  alpha: isSelected ? 0.30 : 0.18,
                                ),
                              );
                            }),
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              final isSelected = states.contains(
                                WidgetState.selected,
                              );
                              return isSelected
                                  ? _brandColor.withValues(alpha: 0.12)
                                  : Colors.white;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              final isSelected = states.contains(
                                WidgetState.selected,
                              );
                              return isSelected
                                  ? _brandColor
                                  : Colors.grey[800];
                            }),
                            iconSize: const WidgetStatePropertyAll(20),
                          ),
                          segments: const [
                            ButtonSegment<int>(
                              value: 0,
                              label: Text('بيانات المركز'),
                              icon: Icon(Icons.assignment_outlined),
                            ),
                            ButtonSegment<int>(
                              value: 1,
                              label: Text('إدارة الحجز'),
                              icon: Icon(Icons.manage_history),
                            ),
                          ],
                          selected: <int>{_activeCenterSection},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            if (selection.isEmpty) return;
                            setState(
                              () => _activeCenterSection = selection.first,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_activeCenterSection == 0) ...[
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
                                if (value.isEmpty) {
                                  return 'من فضلك أدخل اسم المركز';
                                }
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
                                if (value.isEmpty) {
                                  return 'من فضلك أدخل العنوان';
                                }
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
                                if (value.isEmpty) {
                                  return 'من فضلك أدخل رقم الهاتف';
                                }
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
                                if (value.isEmpty) {
                                  return 'من فضلك أدخل ساعات العمل';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _cardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitleWithBadge(
                              'إدارة طلبات الحجز',
                              icon: Icons.manage_history,
                              subtitle:
                                  'تابع الطلبات ووافق/ارفض (سيتم تفعيلها عند ربط قاعدة البيانات)',
                              badgeText: _bookingEnabled
                                  ? 'مفعّل'
                                  : 'غير مفعّل',
                              badgeColor: _bookingEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _brandColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _brandColor.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _brandColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.event_note_rounded,
                                          color: _brandColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'طلبات الحجز',
                                          style: TextStyle(
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
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: _brandColor.withValues(
                                              alpha: 0.18,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '0 جديد',
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
                                  Text(
                                    _bookingEnabled
                                        ? 'لا توجد طلبات حجز حالياً.'
                                        : 'فعّل الحجز أولاً ليتم استقبال الطلبات.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _submitting
                                          ? null
                                          : () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'لا توجد طلبات بعد (Demo)',
                                                  ),
                                                ),
                                              );
                                            },
                                      icon: const Icon(Icons.refresh),
                                      label: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Text('تحديث'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_activeCenterSection == 0) ...[
                      _cardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitleWithBadge(
                              'إضافة أطباء المركز',
                              icon: Icons.people_alt_outlined,
                              subtitle: 'اختياري — أضف أطباء المركز وبياناتهم',
                              badgeText: _doctors.isEmpty
                                  ? 'اختياري'
                                  : '${_doctors.length}',
                              badgeColor: Colors.deepPurple,
                            ),
                            const SizedBox(height: 10),
                            if (_doctors.isEmpty)
                              Text(
                                'لم يتم إضافة أطباء بعد',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              )
                            else
                              ..._doctors.asMap().entries.map((entry) {
                                final i = entry.key;
                                final doc = entry.value;
                                final photoUrl = doc.photoUrlController.text
                                    .trim();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _brandColor.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _brandColor.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'طبيب ${i + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _brandColor,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: 'حذف',
                                            onPressed: _submitting
                                                ? null
                                                : () => _removeDoctor(i),
                                            icon: Icon(
                                              Icons.close_rounded,
                                              color: Colors.red[400],
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap:
                                                (_submitting ||
                                                    _uploadingDoctorIndex == i)
                                                ? null
                                                : () =>
                                                      _pickAndUploadDoctorPhoto(
                                                        i,
                                                      ),
                                            child: Container(
                                              width: 78,
                                              height: 78,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: _brandColor.withValues(
                                                    alpha: 0.25,
                                                  ),
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: _uploadingDoctorIndex == i
                                                  ? Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: _brandColor,
                                                          ),
                                                    )
                                                  : (photoUrl.isNotEmpty &&
                                                        _isHttpUrl(photoUrl))
                                                  ? Image.network(
                                                      photoUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Center(
                                                              child: Icon(
                                                                Icons
                                                                    .broken_image_outlined,
                                                                color: Colors
                                                                    .grey[500],
                                                              ),
                                                            );
                                                          },
                                                    )
                                                  : Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .add_a_photo_outlined,
                                                          color: _brandColor,
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'صورة',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: _brandColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                TextFormField(
                                                  controller:
                                                      doc.nameController,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration: _inputDecoration(
                                                    label: 'اسم الطبيب',
                                                    hint: 'مثال: أحمد محمد',
                                                    icon: Icons.person_rounded,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                TextFormField(
                                                  controller:
                                                      doc.titleController,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration: _inputDecoration(
                                                    label: 'اللقب / التخصص',
                                                    hint: 'مثال: أخصائي باطنة',
                                                    icon: Icons
                                                        .workspace_premium_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _submitting ? null : _addDoctor,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text('إضافة طبيب'),
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
                              'إعدادات الحجز',
                              icon: Icons.event_available,
                              subtitle:
                                  'فعّل الحجز وحدد الطرق والسعة لعرضها للمستخدمين',
                              badgeText: _bookingEnabled
                                  ? 'مفعّل'
                                  : 'غير مفعّل',
                              badgeColor: _bookingEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: _brandColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _brandColor.withValues(alpha: 0.12),
                                ),
                              ),
                              child: SwitchListTile(
                                value: _bookingEnabled,
                                onChanged: (v) {
                                  setState(() {
                                    _bookingEnabled = v;
                                    if (!v) {
                                      _bookingMethods.clear();
                                      _bookingUrlController.clear();
                                      _bookingNotesController.clear();
                                    } else {
                                      // اقتراح افتراضي ذكي
                                      _bookingMethods
                                        ..add('اتصال هاتفي')
                                        ..add('واتساب');
                                    }
                                  });
                                },
                                title: const Text(
                                  'تفعيل الحجز في المركز',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  _bookingEnabled
                                      ? 'سيظهر زر/معلومات الحجز للمستخدم'
                                      : 'لن يظهر الحجز للمستخدمين',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                activeThumbColor: _brandColor,
                                activeTrackColor: _brandColor.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              alignment: Alignment.topCenter,
                              child: _bookingEnabled
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 12),
                                        Text(
                                          'طرق الحجز',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _bookingMethodOptions.map((
                                            m,
                                          ) {
                                            final selected = _bookingMethods
                                                .contains(m);
                                            return FilterChip(
                                              label: Text(m),
                                              selected: selected,
                                              onSelected: (v) {
                                                setState(() {
                                                  if (v) {
                                                    _bookingMethods.add(m);
                                                  } else {
                                                    _bookingMethods.remove(m);
                                                  }
                                                });
                                              },
                                              selectedColor: _brandColor
                                                  .withValues(alpha: 0.18),
                                              checkmarkColor: _brandColor,
                                              backgroundColor: Colors.white,
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: _brandColor.withValues(
                                                alpha: 0.12,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'السعة',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$_bookingPatientsPerHour مريض/ساعة',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Slider(
                                                value: _bookingPatientsPerHour
                                                    .toDouble(),
                                                min: 1,
                                                max: 12,
                                                divisions: 11,
                                                label:
                                                    '$_bookingPatientsPerHour',
                                                activeColor: _brandColor,
                                                onChanged: (v) {
                                                  setState(() {
                                                    _bookingPatientsPerHour = v
                                                        .round();
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (_bookingMethods.contains(
                                          'رابط خارجي',
                                        ))
                                          TextFormField(
                                            controller: _bookingUrlController,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: _inputDecoration(
                                              label:
                                                  'رابط الحجز (اختياري/حسب الطريقة)',
                                              hint:
                                                  'https://...'
                                                  ' (رابط مباشر لصفحة الحجز)',
                                              icon: Icons.link,
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _bookingNotesController,
                                          maxLines: 3,
                                          decoration: _inputDecoration(
                                            label: 'ملاحظات الحجز (اختياري)',
                                            hint:
                                                'مثال: يرجى الحضور قبل الموعد بـ 10 دقائق',
                                            icon: Icons.info_outline,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
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
                              subtitle:
                                  'اختياري — يساعد المستخدم للوصول للمركز بسرعة',
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
                              subtitle:
                                  'يمكنك لصق روابط أيضاً، أو رفع من الجهاز',
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
                            if (_coverImageController.text
                                .trim()
                                .isNotEmpty) ...[
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
                                                      alignment:
                                                          Alignment.center,
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
                                                color: Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
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
                                      color: _brandColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _brandColor.withValues(
                                          alpha: 0.22,
                                        ),
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
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          color:
                                                              Colors.grey[500],
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
                                  child: Text(
                                    'إضافة صور للمعرض (رفع من الجهاز)',
                                  ),
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
                                    backgroundColor: _brandColor.withValues(
                                      alpha: 0.10,
                                    ),
                                    deleteIconColor: _brandColor,
                                    labelStyle: TextStyle(
                                      color: _brandColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: _brandColor.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                'لم يتم اختيار تخصصات بعد',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _servicesController,
                              maxLines: 1,
                              decoration: _inputDecoration(
                                label: 'إضافة خدمة (اختياري)',
                                hint: 'مثال: أشعة',
                                icon: Icons.miscellaneous_services,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _addServicesFromInput(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'أضف كل خدمة على حدة باستخدام زر +',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'إضافة',
                                  onPressed: _addServicesFromInput,
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: _brandColor,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedServices.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedServices.map((s) {
                                  return InputChip(
                                    label: Text(s),
                                    onDeleted: () => _removeService(s),
                                    backgroundColor: _brandColor.withValues(
                                      alpha: 0.10,
                                    ),
                                    deleteIconColor: _brandColor,
                                    labelStyle: TextStyle(
                                      color: _brandColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: _brandColor.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                'لم يتم إضافة خدمات بعد',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.10,
                                    ),
                                    deleteIconColor: Colors.green,
                                    labelStyle: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: Colors.green.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                'لم يتم اختيار مميزات بعد',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _submitting
                                ? 'جارٍ الحفظ...'
                                : (_existingCenterId == null
                                    ? 'حفظ'
                                    : 'تحديث'),
                          ),
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

class _MedicalCenterDoctorEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController photoUrlController = TextEditingController();

  void dispose() {
    nameController.dispose();
    titleController.dispose();
    photoUrlController.dispose();
  }
}
