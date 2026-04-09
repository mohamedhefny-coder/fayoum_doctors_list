import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin_login_screen.dart';
import 'screens/doctor_login_screen.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/doctor_detail_screen.dart';
import 'screens/specialty_doctors_screen.dart';
import 'screens/quick_actions_screen.dart';
import 'screens/my_appointments_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/private_hospitals_screen.dart';
import 'screens/government_hospitals_screen.dart';
import 'screens/labs_screen.dart';
import 'screens/radiology_screen.dart';
import 'screens/medical_centers_screen.dart';
import 'screens/pharmacies_screen.dart';
import 'screens/search_overlay_screen.dart';
import 'supabase_config.dart';
import 'services/doctor_database_service.dart';
import 'services/notification_service.dart';
import 'services/doctor_realtime_notifications_service.dart';
import 'models/doctor_model.dart';
import 'screens/doctor_messages_screen.dart';
import 'widgets/doctor_summary_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  await NotificationService.init();
  runApp(const FayoumDoctorsApp());
}

class FayoumDoctorsApp extends StatefulWidget {
  const FayoumDoctorsApp({super.key});

  @override
  State<FayoumDoctorsApp> createState() => _FayoumDoctorsAppState();
}

class _FayoumDoctorsAppState extends State<FayoumDoctorsApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _appLinks = AppLinks();
  final _dbService = DoctorDatabaseService();
  StreamSubscription<Uri>? _linkSub;
  bool _isHandlingLink = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleIncomingLink(initial);
      }
    } catch (e) {
      _showSnack('تعذر قراءة الرابط عند فتح التطبيق.');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (_) => _showSnack('تعذر قراءة الرابط. حاول مرة أخرى.'),
    );
  }

  void _handleIncomingLink(Uri uri) {
    final doctorId = _extractDoctorId(uri);
    if (doctorId == null) return;
    _openDoctorProfile(doctorId);
  }

  String? _extractDoctorId(Uri uri) {
    if (uri.scheme != 'fayoumdoctors') return null;

    if (uri.host == 'doctor') {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first.trim();
      }
      final fromQuery = uri.queryParameters['id'];
      return fromQuery?.trim().isNotEmpty == true ? fromQuery : null;
    }

    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'doctor') {
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments[1].trim();
      }
      final fromQuery = uri.queryParameters['id'];
      return fromQuery?.trim().isNotEmpty == true ? fromQuery : null;
    }

    return null;
  }

  Future<void> _openDoctorProfile(String doctorId) async {
    if (_isHandlingLink) return;
    _isHandlingLink = true;

    try {
      final doctor = await _dbService.getDoctorById(doctorId: doctorId);
      if (doctor == null) {
        _showSnack('لم يتم العثور على الطبيب المطلوب.');
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = _navigatorKey.currentState;
        if (nav == null) return;
        nav.push(
          MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(
              doctor: doctor,
              cardColor: AppColors.primary,
            ),
          ),
        );
      });
    } catch (_) {
      _showSnack('تعذر فتح صفحة الطبيب.');
    } finally {
      _isHandlingLink = false;
    }
  }

  void _showSnack(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دليل أطباء الفيوم',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.almaraiTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _wrapWithWebFrame(child ?? const SizedBox.shrink());
      },
      home: const HomePage(),
    );
  }

  Widget _wrapWithWebFrame(Widget child) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) return child;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.06),
                const Color(0xFFEEF2F7),
                AppColors.secondary.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppColors {
  static const primary = Color(0xFF00BCD4); // Teal
  static const primaryDark = Color(0xFF0097A7); // Teal Dark
  static const secondary = Color(0xFFFF5722); // Deep Orange
  static const accent = Color(0xFFFFEB3B); // Yellow
  static const success = Color(0xFF4CAF50); // Green
  static const purple = Color(0xFF9C27B0); // Purple
  static const pink = Color(0xFFE91E63); // Pink
  static const background = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const cardBg = Colors.white;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  int _selectedIndex = 0;
  Doctor? _currentDoctor;
  final _dbService = DoctorDatabaseService();

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        DoctorRealtimeNotificationsService.stop();
        if (mounted) {
          setState(() {
            _currentDoctor = null;
          });
        }
      }
      if (data.event == AuthChangeEvent.signedIn) {
        _loadCurrentDoctor();
      }
    });

    _loadCurrentDoctor();
  }

  Future<void> _loadCurrentDoctor() async {
    if (SupabaseConfig.isUserLoggedIn) {
      try {
        final doctor = await _dbService.getCurrentDoctorProfile();
        if (mounted) {
          setState(() {
            _currentDoctor = doctor;
          });

          if (doctor != null) {
            await DoctorRealtimeNotificationsService.startForDoctor(doctor.id);
          }
        }
      } catch (e) {
        // في حالة حدوث خطأ، نبقي _currentDoctor كـ null
        debugPrint('Error loading current doctor: $e');
      }
    } else {
      await DoctorRealtimeNotificationsService.stop();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _floatingController.dispose();
    super.dispose();
  }

  void _handleNavTap(BuildContext context, int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountPage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildScrollableContent(BuildContext context) {
    return Stack(
      children: [
        _DecorativeBackground(),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _CreativeHeader(
                  floatingController: _floatingController,
                  currentDoctor: _currentDoctor,
                  onDoctorLogin: _loadCurrentDoctor,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ModernSearchBar(),
                      const SizedBox(height: 28),
                      const _QuickCategories(),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'التخصصات الشائعة',
                        icon: Icons.star_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllSpecialtiesPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const _TrendingSpecialties(),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'أطباء موصى بهم',
                        icon: Icons.verified,
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      const _RecommendedDoctors(),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'خدمات أخرى',
                        icon: Icons.medical_services,
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      const _AdditionalServices(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebWide = kIsWeb && screenWidth > 900;

    if (isWebWide) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFEEF2F7),
          body: Row(
            textDirection: TextDirection.ltr,
            children: [
              _WebSideNav(
                selectedIndex: _selectedIndex,
                currentDoctor: _currentDoctor,
                onTap: (index) => _handleNavTap(context, index),
              ),
              Expanded(child: _buildScrollableContent(context)),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _buildScrollableContent(context),
        bottomNavigationBar: _CustomBottomBar(
          selectedIndex: _selectedIndex,
          onTap: (index) => _handleNavTap(context, index),
        ),
        floatingActionButton: _FloatingBookButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

// ====== شريط التنقل الجانبي للويب ======
class _WebSideNav extends StatelessWidget {
  const _WebSideNav({
    required this.selectedIndex,
    required this.onTap,
    this.currentDoctor,
  });

  final int selectedIndex;
  final Function(int) onTap;
  final Doctor? currentDoctor;

  static const _items = [
    _WebNavItem(Icons.home_rounded, 'الرئيسية'),
    _WebNavItem(Icons.calendar_month_rounded, 'مواعيدي'),
    _WebNavItem(Icons.favorite_rounded, 'المفضلة'),
    _WebNavItem(Icons.person_rounded, 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'دليل أطباء',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'الفيوم',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Nav items ──
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            final isSelected = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Divider(height: 32, indent: 20, endIndent: 20),

          // ── تواصل معنا ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'تواصل معنا',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Admin ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'لوحة الإدارة',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Quick actions button ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuickActionsScreen()),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 20),
                label: const Text(
                  'إجراء سريع',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WebNavItem {
  final IconData icon;
  final String label;

  const _WebNavItem(this.icon, this.label);
}

// ====== خلفية مزخرفة ======
class _DecorativeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.background,
                AppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ====== رأس الصفحة الإبداعي ======
class _CreativeHeader extends StatelessWidget {
  const _CreativeHeader({
    required this.floatingController,
    this.currentDoctor,
    this.onDoctorLogin,
  });

  final AnimationController floatingController;
  final Doctor? currentDoctor;
  final VoidCallback? onDoctorLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.only(bottom: 20),
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // صورة السواقي كخلفية
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset('assets/images/saqiya.jpg', fit: BoxFit.cover),
            ),
          ),
          // طبقة تدرج لوني فوق الصورة
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.45),
                    AppColors.primaryDark.withValues(alpha: 0.55),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          // المحتوى
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: _HeaderContent(
              floatingController: floatingController,
              currentDoctor: currentDoctor,
              onDoctorLogin: onDoctorLogin,
            ),
          ),
        ],
      ),
    );
  }
}

// محتوى الرأس
class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.floatingController,
    this.currentDoctor,
    this.onDoctorLogin,
  });

  final AnimationController floatingController;
  final Doctor? currentDoctor;
  final VoidCallback? onDoctorLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _handleDoctorShortcut(context, onDoctorLogin),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.95),
                  backgroundImage: currentDoctor?.profileImageUrl != null
                      ? NetworkImage(currentDoctor!.profileImageUrl!)
                      : null,
                  child: currentDoctor?.profileImageUrl == null
                      ? Icon(Icons.person, color: AppColors.primary, size: 28)
                      : null,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ContactUsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'تواصل معنا',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (currentDoctor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('الإشعارات متاحة لحسابات الأطباء فقط حالياً'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const DoctorMessagesScreen(),
                          ),
                        )
                        .then((_) =>
                            DoctorRealtimeNotificationsService.markAllSeen());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: StreamBuilder<int>(
                      stream: DoctorRealtimeNotificationsService
                          .notificationCountStream,
                      initialData: 0,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        final showBadge =
                            currentDoctor != null && count > 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            if (showBadge)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 99 ? '99+' : '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اهلاً بك في',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'دليل أطباء الفيوم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'الفيوم، مصر',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -8,
                    math.sin(floatingController.value * 2 * math.pi) * 10,
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/caduceus.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _handleDoctorShortcut(
    BuildContext context,
    VoidCallback? onDoctorLogin,
  ) {
    if (!SupabaseConfig.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إعادة المحاولة بعد تهيئة الاتصال بالخادم.'),
        ),
      );
      return;
    }

    if (SupabaseConfig.isUserLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorLoginScreen()),
      ).then((_) {
        // عند العودة من صفحة تسجيل الدخول، نحاول تحميل بيانات الطبيب
        if (onDoctorLogin != null) {
          onDoctorLogin();
        }
      });
    }
  }
}

// ====== شريط بحث حديث ======
class _ModernSearchBar extends StatelessWidget {
  const _ModernSearchBar();

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const SearchOverlayScreen(),
        transitionsBuilder: (_, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.search, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ابحث عن طبيبك',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'التخصص، الاسم، الخدمة...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== الفئات السريعة ======
class _QuickCategories extends StatelessWidget {
  const _QuickCategories();

  static const categoriesRow1 = [
    _QuickCategory('طوارئ', Icons.emergency, Color(0xFFEF4444)),
    _QuickCategory(
      'مراكز أشعة',
      Icons.medical_information,
      AppColors.purple,
      imagePath: 'assets/images/radiology.png',
    ),
    _QuickCategory(
      'صيدليات',
      Icons.local_pharmacy,
      AppColors.success,
      imagePath: 'assets/images/pharmacy.png',
    ),
    _QuickCategory(
      'معامل',
      Icons.biotech,
      AppColors.pink,
      imagePath: 'assets/images/lab.png',
    ),
  ];

  static const categoriesRow2 = [
    _QuickCategory('مستشفيات حكومية', Icons.local_hospital, Color(0xFF2196F3)),
    _QuickCategory('مستشفيات خاصة', Icons.business, Color(0xFFFF9800)),
    _QuickCategory('مراكز طبية', Icons.medical_services, Color(0xFF00BCD4)),
    _QuickCategory(
      'بنوك الدم',
      Icons.bloodtype,
      Color(0xFFE91E63),
      imagePath: 'assets/images/bloodbank.PNG',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الصف الأول
        Row(
          children: categoriesRow1.map((cat) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _QuickCategoryCard(category: cat),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // الصف الثاني
        Row(
          children: categoriesRow2.map((cat) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _QuickCategoryCard(category: cat),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickCategory {
  final String label;
  final IconData icon;
  final Color color;
  final String? imagePath;

  const _QuickCategory(this.label, this.icon, this.color, {this.imagePath});
}

class _QuickCategoryCard extends StatelessWidget {
  const _QuickCategoryCard({required this.category});

  final _QuickCategory category;

  @override
  Widget build(BuildContext context) {
    const iconSize = 70.0;

    void openCategory() {
      if (category.label == 'مستشفيات حكومية') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GovernmentHospitalsScreen()),
        );
        return;
      }

      if (category.label == 'مستشفيات خاصة') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivateHospitalsScreen()),
        );
        return;
      }

      if (category.label == 'معامل') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LabsScreen()),
        );
        return;
      }

      if (category.label == 'مراكز أشعة') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RadiologyScreen()),
        );
        return;
      }

      if (category.label == 'مراكز طبية') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicalCentersScreen()),
        );
        return;
      }

      if (category.label == 'صيدليات') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PharmaciesScreen()),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('قريباً')));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openCategory,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: category.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: Center(
                  child: category.imagePath != null
                      ? Image.asset(
                          category.imagePath!,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              category.icon,
                              color: category.color,
                              size: iconSize,
                            );
                          },
                        )
                      : Icon(
                          category.icon,
                          color: category.color,
                          size: iconSize,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  category.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: category.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    height: 1.2,
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

// ====== عنوان القسم ======
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Row(
            children: [
              Text(
                'المزيد',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_back_ios, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

// ====== التخصصات الشائعة ======
class _TrendingSpecialties extends StatelessWidget {
  const _TrendingSpecialties();

  static const specialties = [
    _Specialty(
      'طب عام',
      null,
      Color(0xFF00BCD4),
      '40 طبيب',
      imagePath: 'assets/images/general_medicine.png',
    ),
    _Specialty(
      'باطنة',
      null,
      Color(0xFFFF5722),
      '45 طبيب',
      imagePath: 'assets/images/internal_medicine.png',
    ),
    _Specialty(
      'أطفال وحديثي الولادة',
      FontAwesomeIcons.childReaching,
      Color(0xFF2196F3),
      '38 طبيب',
      imagePath: 'assets/images/pediatrics.png',
    ),
    _Specialty(
      'أسنان',
      null,
      Color(0xFF9C27B0),
      '52 طبيب',
      imagePath: 'assets/images/tooth.png',
    ),
    _Specialty(
      'عظام',
      null,
      Color(0xFF00BCD4),
      '29 طبيب',
      imagePath: 'assets/images/orthopedics.png',
    ),
    _Specialty(
      'جلدية',
      FontAwesomeIcons.handDots,
      Color(0xFF4CAF50),
      '34 طبيب',
      imagePath: 'assets/images/dermatology.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: specialties.length,
      itemBuilder: (context, index) {
        return _SpecialtyCard(specialty: specialties[index]);
      },
    );
  }
}

class _Specialty {
  final String name;
  final IconData? icon;
  final String? imagePath;
  final double imageScale;
  final Color color;
  final String count;

  const _Specialty(
    this.name,
    this.icon,
    this.color,
    this.count, {
    this.imagePath,
    this.imageScale = 1.0,
  });
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({required this.specialty});

  final _Specialty specialty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpecialtyDoctorsScreen(
              specialtyName: specialty.name,
              specialtyColor: specialty.color,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: specialty.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                  child: Center(
                    child: specialty.imagePath != null
                        ? Transform.scale(
                            scale: specialty.imageScale,
                            child: Image.asset(
                              specialty.imagePath!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) {
                                if (specialty.icon != null) {
                                  // Try to use as Material Icon first, fallback to FontAwesome
                                  if (specialty.icon!.fontFamily ==
                                      'MaterialIcons') {
                                    return Icon(
                                      specialty.icon!,
                                      color: specialty.color,
                                      size: 100,
                                    );
                                  } else {
                                    return FaIcon(
                                      specialty.icon!,
                                      color: specialty.color,
                                      size: 100,
                                    );
                                  }
                                }
                                return Icon(
                                  Icons.local_hospital,
                                  color: specialty.color,
                                  size: 100,
                                );
                              },
                            ),
                          )
                        : specialty.icon != null
                        ? (specialty.icon!.fontFamily == 'MaterialIcons'
                              ? Icon(
                                  specialty.icon!,
                                  color: specialty.color,
                                  size: 100,
                                )
                              : FaIcon(
                                  specialty.icon!,
                                  color: specialty.color,
                                  size: 100,
                                ))
                        : Icon(
                            Icons.local_hospital,
                            color: specialty.color,
                            size: 100,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      specialty.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (specialty.count.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialty.count,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

// ====== صفحة كل التخصصات الطبية ======
class AllSpecialtiesPage extends StatelessWidget {
  const AllSpecialtiesPage({super.key});

  static const _allSpecialties = [
    _Specialty(
      'طب عام',
      null,
      Color(0xFF00BCD4),
      '',
      imagePath: 'assets/images/general_medicine.png',
    ),
    _Specialty(
      'أسنان',
      null,
      Color(0xFF9C27B0),
      '',
      imagePath: 'assets/images/tooth.png',
    ),
    _Specialty(
      'علاج طبيعي',
      FontAwesomeIcons.personWalking,
      Color(0xFF4CAF50),
      '',
      imagePath: 'assets/images/physiotherapy.png',
    ),
    _Specialty(
      'طب الأسرة',
      FontAwesomeIcons.peopleRoof,
      Color(0xFF2196F3),
      '',
      imagePath: 'assets/images/family medicine.jpg',
    ),
    _Specialty(
      'باطنة (أمراض باطنة)',
      null,
      Color(0xFFFF5722),
      '',
      imagePath: 'assets/images/internal_medicine.png',
    ),
    _Specialty(
      'قلب وأوعية دموية',
      null,
      Color(0xFFE91E63),
      '',
      imagePath: 'assets/images/heart.png',
    ),
    _Specialty(
      'صدرية (أمراض الصدر)',
      null,
      Color(0xFF00BCD4),
      '',
      imagePath: 'assets/images/chest.png',
    ),
    _Specialty(
      'جهاز هضمي وكبد',
      null,
      Color(0xFF4CAF50),
      '',
      imagePath: 'assets/images/digestive.PNG',
    ),
    _Specialty(
      'كُلى (أمراض الكلى)',
      null,
      Color(0xFF2196F3),
      '',
      imagePath: 'assets/images/kidney.PNG',
    ),
    _Specialty(
      'غدد صماء وسكر',
      FontAwesomeIcons.syringe,
      Color(0xFFFF9800),
      '',
      imagePath: 'assets/images/sugar.jpg',
      imageScale: 1.15,
    ),
    _Specialty(
      'روماتيزم ومناعة',
      FontAwesomeIcons.personCane,
      Color(0xFF9C27B0),
      '',
      imagePath: 'assets/images/roma.jpg',
    ),
    _Specialty(
      'أمراض دم',
      null,
      Color(0xFFE91E63),
      '',
      imagePath: 'assets/images/hematology.png',
    ),
    _Specialty(
      'طب الأورام',
      FontAwesomeIcons.ribbon,
      Color(0xFFFF5722),
      '',
      imagePath: 'assets/images/onco.jpg',
    ),
    _Specialty(
      'حساسية ومناعة',
      FontAwesomeIcons.shieldHeart,
      Color(0xFF4CAF50),
      '',
      imagePath: 'assets/images/sens.jpg',
    ),
    _Specialty(
      'طب المخ والأعصاب',
      null,
      Color(0xFF9C27B0),
      '',
      imagePath: 'assets/images/brain.png',
    ),
    _Specialty(
      'نفسية (طب نفسي)',
      FontAwesomeIcons.headSideVirus,
      Color(0xFF2196F3),
      '',
      imagePath: 'assets/images/psychat.jpg',
      imageScale: 1.25,
    ),
    _Specialty(
      'جلدية وتناسلية',
      FontAwesomeIcons.handDots,
      Color(0xFF4CAF50),
      '',
      imagePath: 'assets/images/dermatology.png',
    ),
    _Specialty(
      'أنف وأذن وحنجرة',
      FontAwesomeIcons.earListen,
      Color(0xFFFF9800),
      '',
    ),
    _Specialty(
      'رمد',
      null,
      Color(0xFFFF9800),
      '',
      imagePath: 'assets/images/eye.png',
    ),
    _Specialty(
      'جراحة عامة',
      null,
      Color(0xFFFF5722),
      '',
      imagePath: 'assets/images/surgery.png',
    ),
    _Specialty(
      'جراحة عظام',
      null,
      Color(0xFF00BCD4),
      '',
      imagePath: 'assets/images/orthopedics.png',
    ),
    _Specialty(
      'جراحة قلب وصدر',
      FontAwesomeIcons.heart,
      Color(0xFFE91E63),
      '',
      imagePath: 'assets/images/cardiothoracic.jpg',
    ),
    _Specialty(
      'جراحة أوعية دموية',
      FontAwesomeIcons.circleNodes,
      Color(0xFF00BCD4),
      '',
      imagePath: 'assets/images/vascular surgey.png',
    ),
    _Specialty(
      'جراحة الأورام',
      FontAwesomeIcons.dna,
      Color(0xFFFF5722),
      '',
      imagePath: 'assets/images/oncosurg.jpg',
    ),
    _Specialty(
      'جراحة المخ والأعصاب',
      null,
      Color(0xFF00BCD4),
      '',
      imagePath: 'assets/images/neurosurgery.png',
    ),
    _Specialty(
      'جراحة تجميل',
      FontAwesomeIcons.faceLaughBeam,
      Color(0xFF9C27B0),
      '',
      imagePath: 'assets/images/plastic.png',
    ),
    _Specialty(
      'جراحات السمنة',
      FontAwesomeIcons.weightScale,
      Color(0xFF4CAF50),
      '',
      imagePath: 'assets/images/obese.jpg',
    ),
    _Specialty(
      'جراحة الوجه والفكين',
      FontAwesomeIcons.faceSmile,
      Color(0xFFFF9800),
      '',
      imagePath: 'assets/images/maxillo.jpg',
      imageScale: 1.35,
    ),
    _Specialty(
      'جراحة أطفال',
      FontAwesomeIcons.childReaching,
      Color(0xFF2196F3),
      '',
      imagePath: 'assets/images/ped.jpg',
      imageScale: 1.25,
    ),
    _Specialty(
      'جراحة مسالك بولية',
      null,
      Color(0xFF2196F3),
      '',
      imagePath: 'assets/images/urology.png',
      imageScale: 1.25,
    ),
    _Specialty(
      'ذكورة وعقم',
      FontAwesomeIcons.personDress,
      Color(0xFF00BCD4),
      '',
      imagePath: 'assets/images/andrology.jpg',
    ),
    _Specialty(
      'نساء وتوليد',
      FontAwesomeIcons.personPregnant,
      Color(0xFFE91E63),
      '',
      imagePath: 'assets/images/gyna,obs.jpg',
    ),
    _Specialty(
      'أطفال وحديثي الولادة',
      FontAwesomeIcons.childReaching,
      Color(0xFF2196F3),
      '',
      imagePath: 'assets/images/pediatrics.png',
    ),
    _Specialty(
      'مخ وأعصاب أطفال',
      FontAwesomeIcons.childDress,
      Color(0xFF9C27B0),
      '',
      imagePath: 'assets/images/brainped.jpg',
      imageScale: 1.15,
    ),
    _Specialty(
      'تغذية علاجية',
      FontAwesomeIcons.appleWhole,
      Color(0xFFFF9800),
      '',
      imagePath: 'assets/images/nut.jpg',
      imageScale: 1.25,
    ),
    _Specialty(
      'علاج الألم',
      FontAwesomeIcons.handHoldingMedical,
      Color(0xFFFF5722),
      '',
      imagePath: 'assets/images/pain.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('كل التخصصات الطبية'),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: _allSpecialties.length,
            itemBuilder: (context, index) {
              return _SpecialtyCard(specialty: _allSpecialties[index]);
            },
          ),
        ),
      ),
    );
  }
}

// ====== الأطباء الموصى بهم ======
class _RecommendedDoctors extends StatefulWidget {
  const _RecommendedDoctors();

  @override
  State<_RecommendedDoctors> createState() => _RecommendedDoctorsState();
}

class _RecommendedDoctorsState extends State<_RecommendedDoctors> {
  final _dbService = DoctorDatabaseService();
  final PageController _controller = PageController(viewportFraction: 0.92);
  final List<Doctor> _doctors = <Doctor>[];
  final List<_RotationItem> _rotation = <_RotationItem>[];
  Timer? _autoTimer;
  Timer? _reloadDebounce;
  RealtimeChannel? _channel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _reloadDebounce?.cancel();
    _channel?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  void _subscribeRealtime() {
    final channel = Supabase.instance.client.channel('recommended_doctors');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'doctors',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'doctors',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'doctors',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();

    _channel = channel;
  }

  void _scheduleReload() {
    if (!mounted) return;
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctors = await _dbService.getRecommendedDoctors();
      if (!mounted) return;
      _doctors
        ..clear()
        ..addAll(doctors);
      _buildRotation();
      _isLoading = false;
      _startAutoScroll();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _buildRotation() {
    _rotation.clear();
    for (final doctor in _doctors) {
      final weight = _normalizeWeight(doctor.recommendedWeight);
      final duration = _normalizeDuration(doctor.recommendedDurationSeconds);
      for (var i = 0; i < weight; i++) {
        _rotation.add(_RotationItem(doctor, duration));
      }
    }
  }

  int _normalizeWeight(int raw) {
    if (raw <= 0) return 1;
    if (raw > 10) return 10;
    return raw;
  }

  int _normalizeDuration(int raw) {
    if (raw < 2) return 2;
    if (raw > 12) return 12;
    return raw;
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    if (_rotation.length < 2) return;
    _scheduleNextAdvance();
  }

  void _scheduleNextAdvance() {
    _autoTimer?.cancel();
    if (!_controller.hasClients || _rotation.isEmpty) return;
    final current = _controller.page?.round() ?? _controller.initialPage;
    final currentItem = _rotation[current % _rotation.length];
    _autoTimer = Timer(Duration(seconds: currentItem.durationSeconds), () {
      if (!_controller.hasClients || _rotation.isEmpty) return;
      final next = (current + 1) % _rotation.length;
      _controller
          .animateToPage(
            next,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          )
          .whenComplete(_scheduleNextAdvance);
    });
  }

  Color _colorForDoctor(Doctor doctor, int index) {
    const palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.pink,
      AppColors.purple,
      AppColors.success,
    ];
    final hash = doctor.id.hashCode;
    final slot = (hash.abs() + index) % palette.length;
    return palette[slot];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text('تعذر تحميل الأطباء: $_error'),
        ),
      );
    }

    if (_rotation.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('لا يوجد أطباء حالياً.')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWebWide = kIsWeb && screenWidth > 900;

    // على الويب: شبكة 3 بطاقات بدلاً من الكاروسيل
    if (isWebWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.3,
        ),
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          final color = _colorForDoctor(doctor, index);
          return DoctorSummaryCard(
            doctor: doctor,
            cardColor: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailScreen(
                    doctor: doctor,
                    cardColor: color,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // على الموبايل: الكاروسيل الأصلي
    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (_) => _scheduleNextAdvance(),
        itemCount: _rotation.length,
        itemBuilder: (context, index) {
          final item = _rotation[index];
          final doctor = item.doctor;
          final color = _colorForDoctor(doctor, index);

          return Padding(
            padding: const EdgeInsets.only(left: 6, right: 6),
            child: DoctorSummaryCard(
              doctor: doctor,
              cardColor: color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorDetailScreen(
                      doctor: doctor,
                      cardColor: color,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RotationItem {
  final Doctor doctor;
  final int durationSeconds;

  const _RotationItem(this.doctor, this.durationSeconds);
}

// ====== الخدمات الإضافية ======
class _AdditionalServices extends StatelessWidget {
  const _AdditionalServices();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ServiceCard(
            icon: Icons.article,
            title: 'قوافل طبية',
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ServiceCard(
            icon: Icons.medical_services,
            title: 'رسائلي الطبية',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), color],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ====== شريط السفلي المخصص ======
class _CustomBottomBar extends StatelessWidget {
  const _CustomBottomBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.calendar_today,
                label: 'المواعيد',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 60), // مساحة للزر العائم
              _NavItem(
                icon: Icons.favorite_outline,
                label: 'المفضلة',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'حسابي',
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== الزر العائم للحجز ======
class _FloatingBookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuickActionsScreen()),
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 38, color: Colors.white),
      ),
    );
  }
}

// ====== صفحة الحساب ======
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية متدرجة
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.background,
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // رأس الصفحة
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // المحتوى
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // أيقونة كبيرة
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 40),

                          const Text(
                            'مرحباً بك في دليل أطباء الفيوم',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'اختر نوع الحساب للمتابعة',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 50),

                          // بطاقة تسجيل الدخول كطبيب
                          _LoginCard(
                            title: 'تسجيل الدخول كطبيب',
                            subtitle: 'إذا كنت طبيباً وتريد إدارة عيادتك',
                            icon: Icons.medical_services,
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorLoginScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // بطاقة تسجيل الدخول كزائر
                          _LoginCard(
                            title: 'تسجيل الدخول كزائر',
                            subtitle: 'للبحث عن الأطباء وحجز المواعيد',
                            icon: Icons.person_outline,
                            color: AppColors.secondary,
                            onTap: () {
                              // سيتم إضافة صفحة تسجيل الدخول للزائر لاحقاً
                            },
                          ),

                          const SizedBox(height: 30),

                          // متابعة بدون تسجيل
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'متابعة بدون تسجيل الدخول',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
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
          ],
        ),
      ),
    );
  }
}

// بطاقة تسجيل الدخول
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 35),
            ),

            const SizedBox(width: 20),

            // النصوص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // سهم
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== صفحة تسجيل الدخول للطبيب ======
final supabase = Supabase.instance.client;
