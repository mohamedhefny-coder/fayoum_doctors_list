import 'dart:async';
import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_database_service.dart';
import '../widgets/doctor_summary_card.dart';
import 'doctor_detail_screen.dart';

class SearchOverlayScreen extends StatefulWidget {
  const SearchOverlayScreen({super.key});

  @override
  State<SearchOverlayScreen> createState() => _SearchOverlayScreenState();
}

class _SearchOverlayScreenState extends State<SearchOverlayScreen>
    with SingleTickerProviderStateMixin {
  // ─── ألوان ───────────────────────────────────────────────────────────
  static const _primary = Color(0xFF00BCD4);
  static const _secondary = Color(0xFFFF5722);
  static const _bg = Color(0xFFF1F5F9);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

  // ─── حالة ────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _dbService = DoctorDatabaseService();

  List<Doctor> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  String? _selectedSpecialty;
  final Set<String> _activeFilters = {};

  Timer? _debounce;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ─── التخصصات ────────────────────────────────────────────────────────
  static const _specialties = [
    ('طب عام', Color(0xFF00BCD4)),
    ('باطنة (أمراض باطنة)', Color(0xFFFF5722)),
    ('أطفال وحديثي الولادة', Color(0xFF2196F3)),
    ('أسنان', Color(0xFF9C27B0)),
    ('عظام', Color(0xFF00BCD4)),
    ('جلدية وتناسلية', Color(0xFF4CAF50)),
    ('قلب وأوعية دموية', Color(0xFFE91E63)),
    ('طب المخ والأعصاب', Color(0xFF9C27B0)),
    ('نساء وتوليد', Color(0xFFE91E63)),
    ('جراحة عامة', Color(0xFFFF5722)),
    ('رمد', Color(0xFFFF9800)),
    ('أنف وأذن وحنجرة', Color(0xFFFF9800)),
    ('نفسية (طب نفسي)', Color(0xFF2196F3)),
    ('جهاز هضمي وكبد', Color(0xFF4CAF50)),
    ('غدد صماء وسكر', Color(0xFFFF9800)),
    ('مسالك بولية', Color(0xFF2196F3)),
    ('ذكورة وعقم', Color(0xFF00BCD4)),
    ('علاج طبيعي', Color(0xFF4CAF50)),
    ('طب الأسرة', Color(0xFF2196F3)),
    ('جراحة عظام', Color(0xFF00BCD4)),
    ('جراحة تجميل', Color(0xFF9C27B0)),
  ];

  // ─── الفلاتر السريعة ─────────────────────────────────────────────────
  static const _quickFilters = [
    ('حجز أونلاين', Icons.calendar_today_rounded, Color(0xFF00BCD4)),
    ('زيارة منزلية', Icons.home_rounded, Color(0xFF4CAF50)),
    ('طوارئ 24/7', Icons.emergency_rounded, Color(0xFFE53935)),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
    // فتح لوحة المفاتيح بعد الأنيميشن
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── البحث ───────────────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _doSearch);
  }

  Future<void> _doSearch() async {
    final name = _nameCtrl.text.trim();
    final specialty = _selectedSpecialty;
    final hasBooking = _activeFilters.contains('حجز أونلاين');
    final hasHomeVisit = _activeFilters.contains('زيارة منزلية');
    final hasEmergency = _activeFilters.contains('طوارئ 24/7');

    // لا بحث إذا لم يُحدَّد أي معيار
    if (name.isEmpty && specialty == null && _activeFilters.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Doctor> doctors;

      if (specialty != null && name.isEmpty) {
        doctors = await _dbService.getDoctorsBySpecialty(specialty);
      } else if (name.isNotEmpty && specialty == null) {
        doctors = await _dbService.searchDoctorsByName(name);
      } else if (name.isNotEmpty && specialty != null) {
        // دمج النتيجتين
        final byName = await _dbService.searchDoctorsByName(name);
        final bySpec = await _dbService.getDoctorsBySpecialty(specialty);
        final ids = bySpec.map((d) => d.id).toSet();
        doctors = byName.where((d) => ids.contains(d.id)).toList();
      } else {
        doctors = await _dbService.getAllDoctors();
      }

      // تطبيق الفلاتر السريعة
      if (hasBooking) doctors = doctors.where((d) => d.isBookingEnabled).toList();
      if (hasHomeVisit) doctors = doctors.where((d) => d.homeVisit).toList();
      if (hasEmergency) doctors = doctors.where((d) => d.emergency24h).toList();

      if (mounted) {
        setState(() {
          _results = doctors;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
    _doSearch();
  }

  void _selectSpecialty(String name) {
    setState(() {
      _selectedSpecialty = _selectedSpecialty == name ? null : name;
    });
    _doSearch();
  }

  void _clearAll() {
    setState(() {
      _nameCtrl.clear();
      _selectedSpecialty = null;
      _activeFilters.clear();
      _results = [];
      _hasSearched = false;
    });
  }

  // ─── واجهة ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildSearchPanel(),
                    Expanded(child: _buildResultsArea()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── لوحة البحث ──────────────────────────────────────────────────────
  Widget _buildSearchPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006064), Color(0xFF00BCD4)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ابحث عن طبيبك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // زر إغلاق
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── حقل الاسم ───────────────────────────
                _buildNameField(),
                const SizedBox(height: 14),

                // ─── فلاتر سريعة ─────────────────────────
                _buildQuickFilters(),
                const SizedBox(height: 14),

                // ─── التخصصات ────────────────────────────
                const Text(
                  'اختر التخصص',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSpecialtyChips(),
                const SizedBox(height: 12),

                // ─── أزرار الإجراءات ─────────────────────
                _buildActions(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.25)),
      ),
      child: TextField(
        controller: _nameCtrl,
        focusNode: _focusNode,
        textDirection: TextDirection.rtl,
        onChanged: _onSearchChanged,
        onSubmitted: (_) => _doSearch(),
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'اسم الطبيب أو الخدمة...',
          hintStyle:
              const TextStyle(color: _textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.person_search_rounded,
              color: _primary, size: 22),
          suffixIcon: _nameCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: _textSecondary, size: 18),
                  onPressed: () {
                    _nameCtrl.clear();
                    _doSearch();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickFilters.map((f) {
          final (label, icon, color) = f;
          final active = _activeFilters.contains(label);
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => _toggleFilter(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? color
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? color
                        : color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 15,
                        color: active ? Colors.white : color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecialtyChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (name, color) = _specialties[i];
          final selected = _selectedSpecialty == name;
          return GestureDetector(
            onTap: () => _selectSpecialty(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? color
                      : color.withValues(alpha: 0.3),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    final hasAny = _nameCtrl.text.isNotEmpty ||
        _selectedSpecialty != null ||
        _activeFilters.isNotEmpty;

    return Row(
      children: [
        // زر بحث
        Expanded(
          child: GestureDetector(
            onTap: _doSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006064), Color(0xFF00BCD4)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'بحث',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (hasAny) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _secondary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: _secondary, size: 20),
            ),
          ),
        ],
      ],
    );
  }

  // ─── منطقة النتائج ────────────────────────────────────────────────────
  Widget _buildResultsArea() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(
            color: Color(0xFF00BCD4),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_results.isEmpty) {
      return _buildNoResults();
    }

    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded,
                size: 56, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Text(
            'ابحث عن طبيبك',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'أدخل اسم الطبيب أو اختر التخصص',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 56, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد نتائج',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'جرّب تغيير معايير البحث',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        // شريط النتائج
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.fact_check_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'تم العثور على ${_results.length} طبيب',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: _results.length,
            itemBuilder: (ctx, i) {
              final doctor = _results[i];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailScreen(
                      doctor: doctor,
                      cardColor: const Color(0xFF00BCD4),
                    ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DoctorSummaryCard(
                      doctor: doctor,
                      cardColor: const Color(0xFF00BCD4),
                    ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
