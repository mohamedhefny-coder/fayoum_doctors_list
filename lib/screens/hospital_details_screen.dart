import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hospital_model.dart';

class HospitalDetailsScreen extends StatefulWidget {
  const HospitalDetailsScreen({super.key, required this.hospital});

  final HospitalModel hospital;

  @override
  State<HospitalDetailsScreen> createState() => _HospitalDetailsScreenState();
}

class _HospitalDetailsScreenState extends State<HospitalDetailsScreen> {
  bool _showClinics = false;
  bool _showDepartments = false;

  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  Uri? _phoneUri() {
    final phone = widget.hospital.phone?.trim();
    if (phone == null || phone.isEmpty) return null;
    return Uri(scheme: 'tel', path: phone);
  }

  Uri? _mapsUri() {
    if (widget.hospital.hasLocation) {
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.hospital.latitude},${widget.hospital.longitude}',
      );
    }

    final query = [
      widget.hospital.name,
      widget.hospital.address,
    ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).join(' ');

    if (query.trim().isEmpty) return null;

    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phoneUri = _phoneUri();
    final mapsUri = _mapsUri();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.hospital.name)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(hospital: widget.hospital),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'معلومات التواصل',
              icon: Icons.contact_phone,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('العنوان'),
                    subtitle: Text(
                      widget.hospital.address?.trim().isNotEmpty == true
                          ? widget.hospital.address!.trim()
                          : 'العنوان غير متوفر',
                    ),
                    trailing: TextButton(
                      onPressed: mapsUri == null
                          ? null
                          : () => _launchExternal(context, mapsUri),
                      child: const Text('خريطة'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: const Text('الهاتف'),
                    subtitle: Text(
                      widget.hospital.phone?.trim().isNotEmpty == true
                          ? widget.hospital.phone!.trim()
                          : 'غير متوفر',
                    ),
                    trailing: TextButton(
                      onPressed: phoneUri == null
                          ? null
                          : () => _launchExternal(context, phoneUri),
                      child: const Text('اتصال'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'الخدمات',
              icon: Icons.medical_services_outlined,
              child: widget.hospital.services.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('لا توجد خدمات مسجلة حالياً.'),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.hospital.services
                            .map(
                              (s) => Chip(
                                label: Text(s),
                                backgroundColor: colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                side: BorderSide(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
            if (widget.hospital.id == 'general_hospital') ...[
              const SizedBox(height: 16),
              _buildExpandableSectionCard(
                title: 'جدول العيادات الخارجية',
                icon: Icons.calendar_month,
                isExpanded: _showClinics,
                onTap: () => setState(() => _showClinics = !_showClinics),
                child: _buildClinicsSchedule(),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildExpandableSectionCard(
                title: 'الأقسام والوحدات',
                icon: Icons.domain,
                isExpanded: _showDepartments,
                onTap: () =>
                    setState(() => _showDepartments = !_showDepartments),
                child: _buildDepartments(colorScheme),
                colorScheme: colorScheme,
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: phoneUri == null
                        ? null
                        : () => _launchExternal(context, phoneUri),
                    icon: const Icon(Icons.call),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: mapsUri == null
                        ? null
                        : () => _launchExternal(context, mapsUri),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('الموقع'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSectionCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'اضغط للعرض',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isExpanded) ...[const Divider(height: 1), child],
        ],
      ),
    );
  }

  Widget _buildClinicsSchedule() {
    final clinics = [
      {
        'name': 'عيادة الباطنة',
        'days': 'السبت - الإثنين - الأربعاء',
        'time': '9 ص - 2 م',
      },
      {
        'name': 'عيادة الجراحة',
        'days': 'الأحد - الثلاثاء - الخميس',
        'time': '10 ص - 2 م',
      },
      {
        'name': 'عيادة الأطفال',
        'days': 'يومياً عدا الجمعة',
        'time': '9 ص - 3 م',
      },
      {
        'name': 'عيادة النساء والتوليد',
        'days': 'السبت - الثلاثاء - الخميس',
        'time': '10 ص - 2 م',
      },
      {'name': 'عيادة العظام', 'days': 'الأحد - الأربعاء', 'time': '9 ص - 1 م'},
      {
        'name': 'عيادة الأنف والأذن',
        'days': 'السبت - الإثنين',
        'time': '10 ص - 1 م',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (int i = 0; i < clinics.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            _ClinicScheduleItem(
              name: clinics[i]['name']!,
              days: clinics[i]['days']!,
              time: clinics[i]['time']!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartments(ColorScheme colorScheme) {
    final departments = [
      {'name': 'قسم الطوارئ', 'icon': Icons.emergency, 'available': '24 ساعة'},
      {
        'name': 'قسم العناية المركزة',
        'icon': Icons.monitor_heart,
        'available': '24 ساعة',
      },
      {
        'name': 'قسم الأشعة',
        'icon': Icons.medical_information,
        'available': '8 ص - 10 م',
      },
      {
        'name': 'المعامل الطبية',
        'icon': Icons.biotech,
        'available': '8 ص - 8 م',
      },
      {
        'name': 'وحدة الغسيل الكلوي',
        'icon': Icons.water_drop,
        'available': '8 ص - 8 م',
      },
      {'name': 'قسم الجراحة', 'icon': Icons.healing, 'available': '24 ساعة'},
      {
        'name': 'قسم الباطنة',
        'icon': Icons.local_hospital,
        'available': '24 ساعة',
      },
      {'name': 'قسم الأطفال', 'icon': Icons.child_care, 'available': '24 ساعة'},
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: departments
            .map(
              (dept) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          dept['icon'] as IconData,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dept['name'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dept['available'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ClinicScheduleItem extends StatelessWidget {
  const _ClinicScheduleItem({
    required this.name,
    required this.days,
    required this.time,
  });

  final String name;
  final String days;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medical_services,
            size: 20,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      days,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.hospital});

  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final rating = hospital.rating;
    final ratingCount = hospital.ratingCount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(Icons.local_hospital, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating == null ? 'بدون تقييم' : rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (ratingCount != null) ...[
                      const SizedBox(width: 6),
                      Text('($ratingCount)'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}
