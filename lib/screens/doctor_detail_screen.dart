import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/doctor_model.dart';
import '../models/doctor_working_hours.dart';
import '../services/doctor_database_service.dart';
import 'doctor_questions_screen.dart';
import 'intro_video_player_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;
  final Color cardColor;

  const DoctorDetailScreen({
    super.key,
    required this.doctor,
    required this.cardColor,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  double _userRating = 0;
  final GlobalKey _qrKey = GlobalKey();

  String _doctorShareLink() {
    return 'fayoumdoctors://doctor/${widget.doctor.id}';
  }

  Future<Uint8List?> _captureQrPng() async {
    final boundary = _qrKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _showShareSheet() {
    final link = _doctorShareLink();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'مشاركة صفحة الطبيب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: QrImageView(
                      data: link,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final bytes = await _captureQrPng();
                      if (!context.mounted) return;
                      if (bytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر إنشاء كود QR للمشاركة.'),
                          ),
                        );
                        return;
                      }

                      await Share.shareXFiles(
                        [
                          XFile.fromData(
                            bytes,
                            name: 'doctor_qr.png',
                            mimeType: 'image/png',
                          ),
                        ],
                        text: 'كود QR لصفحة الطبيب',
                      );
                    },
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('مشاركة كود QR'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _extractCityFromLocation(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return '';
    final sep = t.contains('|') ? '|' : ' - ';
    final first = t
        .split(sep)
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    return first;
  }

  Color _darken(Color c, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Widget _buildHeroHeader(DoctorDatabaseService db) {
    final doctor = widget.doctor;
    final base = widget.cardColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [base, _darken(base, 0.18)],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: doctor.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(doctor.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: doctor.profileImageUrl == null ? Colors.white : null,
                  ),
                  child: doctor.profileImageUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  doctor.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    ...List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _userRating = index + 1.0;
                          });
                        },
                        child: Icon(
                          index <
                                  (_userRating > 0
                                          ? _userRating
                                          : (doctor.rating ?? 0))
                                      .round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    if (doctor.rating != null && doctor.rating! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doctor.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (_userRating > 0) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: widget.cardColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'إرسال',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (doctor.title != null &&
                    doctor.title!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    doctor.title!.trim(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Pill(
                        icon: Icons.medical_services,
                        label: doctor.specialization,
                        background: Colors.white.withValues(alpha: 0.14),
                        foreground: Colors.white,
                      ),
                      _Pill(
                        icon: Icons.star,
                        label: (doctor.rating ?? 0).toStringAsFixed(1),
                        background: Colors.white.withValues(alpha: 0.14),
                        foreground: Colors.white,
                      ),
                      _Pill(
                        icon: doctor.isBookingEnabled
                            ? Icons.event_available
                            : Icons.event_busy,
                        label: doctor.isBookingEnabled
                            ? 'حجز متاح'
                            : 'الحجز مغلق',
                        background: Colors.white.withValues(alpha: 0.14),
                        foreground: Colors.white,
                        onTap: doctor.isBookingEnabled
                            ? () => _showBookingDialog(context, db)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: _QuickActionIcon(
                            icon: Icons.phone,
                            label: 'اتصال',
                            onTap: () => _makePhoneCall(doctor.phone),
                          ),
                        ),
                        if (doctor.whatsappNumber != null &&
                            doctor.whatsappNumber!.trim().isNotEmpty)
                          Flexible(
                            child: _QuickActionIcon(
                              icon: Icons.chat,
                              label: 'واتساب',
                              onTap: () =>
                                  _openWhatsApp(doctor.whatsappNumber!),
                            ),
                          ),
                        if (doctor.facebookUrl != null &&
                            doctor.facebookUrl!.trim().isNotEmpty)
                          Flexible(
                            child: _QuickActionIcon(
                              icon: Icons.facebook,
                              label: 'فيسبوك',
                              onTap: () => _openUrl(doctor.facebookUrl!),
                            ),
                          ),
                        if (doctor.geoLocation != null &&
                            doctor.geoLocation!.trim().isNotEmpty)
                          Flexible(
                            child: _QuickActionIcon(
                              icon: Icons.place,
                              label: 'الموقع',
                              onTap: () => _openMap(doctor.geoLocation!),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DoctorDatabaseService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: widget.cardColor,
              actions: [
                IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.qr_code_2),
                  onPressed: _showShareSheet,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader(db)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // قسم التخصص والمعلومات الأساسية
                    _buildOrganizedSection(
                      title: 'المعلومات الأساسية',
                      icon: Icons.info_outline,
                      color: const Color(0xFF2196F3),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.medical_services,
                            label: 'التخصص',
                            value: widget.doctor.specialization,
                            color: widget.cardColor,
                          ),
                          if (widget.doctor.qualifications != null &&
                              widget.doctor.qualifications!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.workspace_premium,
                              label: 'الشهادات والمؤهلات',
                              value: widget.doctor.qualifications!,
                              color: widget.cardColor,
                            ),
                          ],
                          if (widget.doctor.bio != null &&
                              widget.doctor.bio!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'السيرة الذاتية',
                              value: widget.doctor.bio!,
                              color: widget.cardColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // قسم الخدمات المقدمة + خدمات مميزة (طوارئ / زيارة منزلية)
                    if ((widget.doctor.services != null &&
                            widget.doctor.services!.trim().isNotEmpty) ||
                        widget.doctor.emergency24h ||
                        widget.doctor.homeVisit) ...[
                      _buildOrganizedSection(
                        title: 'الخدمات المقدمة',
                        icon: Icons.medical_services_outlined,
                        color: const Color(0xFFE91E63),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.doctor.services != null &&
                                widget.doctor.services!.trim().isNotEmpty) ...[
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: widget.doctor.services!
                                    .split('\n')
                                    .where(
                                      (service) => service.trim().isNotEmpty,
                                    )
                                    .map(
                                      (service) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.cardColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              widget.cardColor.withValues(
                                                alpha: 0.05,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: widget.cardColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: widget.cardColor,
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
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (widget.doctor.emergency24h ||
                                widget.doctor.homeVisit) ...[
                              if (widget.doctor.services != null &&
                                  widget.doctor.services!.trim().isNotEmpty)
                                const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (widget.doctor.emergency24h)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFF97316),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.emergency,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'طوارئ 24 ساعة',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (widget
                                                          .doctor
                                                          .emergencyPhone !=
                                                      null &&
                                                  widget.doctor.emergencyPhone!
                                                      .trim()
                                                      .isNotEmpty)
                                                GestureDetector(
                                                  onTap: () => _makePhoneCall(
                                                    widget
                                                        .doctor
                                                        .emergencyPhone!,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.phone,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          widget
                                                              .doctor
                                                              .emergencyPhone!
                                                              .trim(),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.doctor.homeVisit)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF22C55E),
                                            Color(0xFF16A34A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF16A34A,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.home_filled,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'زيارة منزلية متاحة',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // قسم العيادة ومواعيد العمل
                    if (widget.doctor.clinicAddress != null) ...[
                      _buildOrganizedSection(
                        title: 'العيادة ومواعيد العمل',
                        icon: Icons.business,
                        color: const Color(0xFFFF9800),
                        child: Column(
                          children: [
                            // عنوان العيادة
                            GestureDetector(
                              onTap: widget.doctor.geoLocation == null
                                  ? null
                                  : () => _openMap(widget.doctor.geoLocation!),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: widget.cardColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: widget.cardColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'عنوان العيادة',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.cardColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                widget.doctor.clinicAddress!,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.doctor.geoLocation != null)
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: widget.cardColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Builder(
                                      builder: (context) {
                                        final city = _extractCityFromLocation(
                                          widget.doctor.location,
                                        );
                                        if (city.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.cardColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  bottomRight: Radius.circular(
                                                    12,
                                                  ),
                                                ),
                                          ),
                                          child: Text(
                                            city,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // مواعيد العمل
                            FutureBuilder<List<DoctorWorkingHours>>(
                              future: db.getDoctorWorkingHours(
                                doctorId: widget.doctor.id,
                              ),
                              builder: (context, snapshot) {
                                final rows =
                                    snapshot.data ??
                                    const <DoctorWorkingHours>[];
                                final enabled =
                                    rows.where((e) => e.isEnabled).toList()
                                      ..sort(
                                        (a, b) =>
                                            a.dayOfWeek.compareTo(b.dayOfWeek),
                                      );
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (enabled.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                const days = <String>[
                                  'السبت',
                                  'الأحد',
                                  'الاثنين',
                                  'الثلاثاء',
                                  'الأربعاء',
                                  'الخميس',
                                  'الجمعة',
                                ];

                                TextSpan fmt(TimeOfDay? t) {
                                  if (t == null) {
                                    return const TextSpan(
                                      text: 'غير محدد',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }
                                  int hour = t.hour;
                                  String period = 'ص';
                                  if (hour >= 12) {
                                    period = 'م';
                                    if (hour > 12) hour -= 12;
                                  }
                                  if (hour == 0) hour = 12;
                                  final hh = hour.toString().padLeft(2, '0');
                                  final mm = t.minute.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  return TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$hh:$mm ',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: period,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF006400),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final weekday = DateTime.now().weekday;
                                final todayIndex = weekday == 6
                                    ? 0
                                    : (weekday == 7 ? 1 : weekday + 1);

                                TextSpan labelSpan(String text) {
                                  return TextSpan(
                                    text: text,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: widget.cardColor.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: -40,
                                        left: -30,
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.cardColor.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -50,
                                        right: -35,
                                        child: Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.cardColor.withValues(
                                              alpha: 0.06,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topRight,
                                                end: Alignment.bottomLeft,
                                                colors: [
                                                  widget.cardColor,
                                                  _darken(
                                                    widget.cardColor,
                                                    0.18,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.18,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.schedule,
                                                    color: Colors.white,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'جدول المواعيد',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'متاح ${enabled.length} يوم',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.92,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Column(
                                            children: enabled
                                                .map((e) {
                                                  final day =
                                                      (e.dayOfWeek >= 0 &&
                                                          e.dayOfWeek <= 6)
                                                      ? days[e.dayOfWeek]
                                                      : 'يوم';
                                                  final isToday =
                                                      e.dayOfWeek == todayIndex;
                                                  final accent =
                                                      widget.cardColor;

                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isToday
                                                          ? accent.withValues(
                                                              alpha: 0.10,
                                                            )
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: isToday
                                                            ? accent.withValues(
                                                                alpha: 0.45,
                                                              )
                                                            : const Color(
                                                                0xFFE2E8F0,
                                                              ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isToday
                                                                ? accent
                                                                : accent
                                                                      .withValues(
                                                                        alpha:
                                                                            0.10,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                day,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color: isToday
                                                                      ? Colors
                                                                            .white
                                                                      : accent,
                                                                ),
                                                              ),
                                                              if (isToday) ...[
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .white
                                                                        .withValues(
                                                                          alpha:
                                                                              0.20,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          999,
                                                                        ),
                                                                  ),
                                                                  child: const Text(
                                                                    'اليوم',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Align(
                                                            alignment:
                                                                AlignmentDirectional
                                                                    .centerEnd,
                                                            child: RichText(
                                                              textAlign:
                                                                  TextAlign.end,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              text: TextSpan(
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                    0xFF0F172A,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                                children: [
                                                                  labelSpan(
                                                                    'من ',
                                                                  ),
                                                                  fmt(
                                                                    e.startTime,
                                                                  ),
                                                                  const TextSpan(
                                                                    text:
                                                                        '  -  ',
                                                                    style: TextStyle(
                                                                      color: Color(
                                                                        0xFF94A3B8,
                                                                      ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                  labelSpan(
                                                                    'إلى ',
                                                                  ),
                                                                  fmt(
                                                                    e.endTime,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                })
                                                .toList(growable: false),
                                          ),
                                          if (widget.doctor.workingHoursNotes !=
                                                  null &&
                                              widget.doctor.workingHoursNotes!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            const Divider(
                                              color: Color(0xFFFFD700),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.note,
                                                    color: widget.cardColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'ملاحظات',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              widget.cardColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        widget
                                                            .doctor
                                                            .workingHoursNotes!
                                                            .trim(),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Color(
                                                            0xFF1A1A1A,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // زر الحجز
                      InkWell(
                        onTap: widget.doctor.isBookingEnabled
                            ? () => _showBookingDialog(context, db)
                            : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: widget.doctor.isBookingEnabled
                                ? LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      widget.cardColor,
                                      _darken(widget.cardColor, 0.18),
                                    ],
                                  )
                                : null,
                            color: widget.doctor.isBookingEnabled
                                ? null
                                : Colors.grey.shade400,
                            boxShadow: [
                              BoxShadow(
                                color: widget.doctor.isBookingEnabled
                                    ? widget.cardColor.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.event_available,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.doctor.isBookingEnabled
                                          ? 'حجز موعد الآن'
                                          : 'الحجز غير متاح حالياً',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.doctor.isBookingEnabled
                                          ? 'خطوات سريعة داخل التطبيق'
 
                                        : 'جرّب التواصل هاتفياً أو واتساب',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.90,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // قسم الوسائط المتعددة
                    if ((widget.doctor.introVideoUrl != null &&
                            widget.doctor.introVideoUrl!.trim().isNotEmpty) ||
                        (widget.doctor.galleryImageUrls != null &&
                            widget.doctor.galleryImageUrls!.isNotEmpty)) ...[
                      _buildOrganizedSection(
                        title: 'الوسائط المتعددة',
                        icon: Icons.photo_library,
                        color: const Color(0xFF00BCD4),
                        child: Column(
                          children: [
                            if (widget.doctor.introVideoUrl != null &&
                                widget.doctor.introVideoUrl!
                                    .trim()
                                    .isNotEmpty) ...[
                              GestureDetector(
                                onTap: () => _openIntroVideo(
                                  widget.doctor.introVideoUrl!,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.cardColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        widget.cardColor.withValues(
                                          alpha: 0.05,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: widget.cardColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: widget.cardColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'فيديو تعريفي',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'شاهد الفيديو التعريفي للطبيب',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: widget.cardColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (widget.doctor.galleryImageUrls != null &&
                                widget.doctor.galleryImageUrls!.isNotEmpty) ...[
                              if (widget.doctor.introVideoUrl != null &&
                                  widget.doctor.introVideoUrl!
                                      .trim()
                                      .isNotEmpty)
                                const SizedBox(height: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'معرض الصور',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _GalleryStories(
                                    urls: widget.doctor.galleryImageUrls!,
                                    doctorId: widget.doctor.id,
                                    accentColor: widget.cardColor,
                                    onOpen: (index) => _openGalleryViewer(
                                      urls: widget.doctor.galleryImageUrls!,
                                      initialIndex: index,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // بطاقة الأسئلة والاستفسارات
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorQuestionsScreen(
                              doctor: widget.doctor,
                              cardColor: widget.cardColor,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              widget.cardColor,
                              _darken(widget.cardColor, 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: widget.cardColor.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.question_answer,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الأسئلة والاستفسارات',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'اطرح أسئلتك واحصل على إجابات من الطبيب',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withValues(alpha: 0.90),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizedSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 15,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _openGalleryViewer({
    required List<String> urls,
    required int initialIndex,
  }) async {
    if (urls.isEmpty) return;
    final clamped = initialIndex.clamp(0, urls.length - 1);
    final controller = PageController(initialPage: clamped);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'gallery',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (dialogContext, anim1, anim2) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                PageView.builder(
                  controller: controller,
                  itemCount: urls.length,
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    final heroTag = 'doctor_gallery_${widget.doctor.id}_$index';

                    return Center(
                      child: Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 280,
                                  height: 280,
                                  color: Colors.white,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 48),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'إغلاق',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _submitRating() async {
    try {
      final db = DoctorDatabaseService();
      await db.addDoctorRating(doctorId: widget.doctor.id, rating: _userRating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شكراً لك! تم إرسال تقييمك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _userRating = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '20${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('20') && !cleanNumber.startsWith('+')) {
      cleanNumber = '20$cleanNumber';
    }
    cleanNumber = cleanNumber.replaceAll('+', '');

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      final Uri altUri = Uri.parse('whatsapp://send?phone=$cleanNumber');
      if (await canLaunchUrl(altUri)) {
        await launchUrl(altUri);
      }
    }
  }

  void _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _looksLikeDirectVideoUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return false;
    if (u.contains('youtube.com') || u.contains('youtu.be')) return false;
    if (u.contains('vimeo.com')) return false;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.webm') ||
        u.endsWith('.m3u8');
  }

  Future<void> _openIntroVideo(String url) async {
    if (_looksLikeDirectVideoUrl(url)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IntroVideoPlayerScreen(url: url)),
      );
      return;
    }

    _openUrl(url);
  }

  void _openMap(String geoLocation) async {
    final coordinates = geoLocation.split(',');
    if (coordinates.length == 2) {
      final lat = coordinates[0].trim();
      final lng = coordinates[1].trim();

      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      try {
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        final Uri altUri = Uri.parse('geo:$lat,$lng');
        if (await canLaunchUrl(altUri)) {
          await launchUrl(altUri);
        }
      }
    }
  }

  Future<void> _showBookingDialog(
    BuildContext context,
    DoctorDatabaseService db,
  ) async {
    final pageContext = this.context;
    final messenger = ScaffoldMessenger.of(pageContext);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    bool isLoading = false;
    DateTime selectedDate = DateUtils.dateOnly(DateTime.now());

    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    void unfocusKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

    try {
      await showModalBottomSheet<void>(
        context: pageContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              Future<void> pickDate() async {
                unfocusKeyboard();
                final today = DateUtils.dateOnly(DateTime.now());
                final firstDate = today;
                final lastDate = today.add(const Duration(days: 365));
                final initialDate = selectedDate.isBefore(firstDate)
                    ? firstDate
                    : selectedDate;
                final picked = await showDatePicker(
                  context: pageContext,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (picked == null) return;
                setSheetState(() => selectedDate = DateUtils.dateOnly(picked));
              }

              Future<void> submit() async {
                unfocusKeyboard();
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال الاسم ورقم الهاتف.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setSheetState(() => isLoading = true);
                try {
                  // إرسال الموعد بالتاريخ فقط (بدون وقت محدد)
                  await db.createAppointment(
                    doctorId: widget.doctor.id,
                    patientName: name,
                    patientPhone: phone,
                    appointmentDate: selectedDate,
                    appointmentTime: const TimeOfDay(hour: 0, minute: 0),
                  );

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }

                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال طلب الحجز للطبيب بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  setSheetState(() => isLoading = false);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('تعذر إرسال طلب الحجز: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: widget.cardColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.event_available,
                                  color: widget.cardColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'حجز سريع',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.of(sheetContext).pop(),
                                icon: const Icon(Icons.close),
                                tooltip: 'إغلاق',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'سيتم إرسال طلب الحجز للطبيب للمراجعة. بعد قبول الطلب ستظهر طرق الدفع (إن كانت مطلوبة).',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          // معلومات الدفع
                          if (widget.doctor.isPayAtBookingEnabled) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFE082),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.payment,
                                    color: Color(0xFFF57C00),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'الدفع مطلوب عند الحجز',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFFE65100),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'يتطلب الطبيب تأكيد الدفع قبل تثبيت الموعد',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'اسم المريض',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : pickDate,
                            icon: const Icon(Icons.calendar_month),
                            label: Text('التاريخ: ${fmtDate(selectedDate)}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.cardColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'إرسال الطلب',
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
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
    }
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryStories extends StatelessWidget {
  final List<String> urls;
  final String doctorId;
  final Color accentColor;
  final ValueChanged<int> onOpen;

  const _GalleryStories({
    required this.urls,
    required this.doctorId,
    required this.accentColor,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = urls[index];
          final heroTag = 'doctor_gallery_${doctorId}_$index';

          return InkWell(
            onTap: () => onOpen(index),
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: heroTag,
                  child: Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'صورة ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
