import 'package:flutter/material.dart';

import '../models/hospital_model.dart';
import 'hospital_details_screen.dart';

class PrivateHospitalsScreen extends StatefulWidget {
  const PrivateHospitalsScreen({super.key});

  @override
  State<PrivateHospitalsScreen> createState() => _PrivateHospitalsScreenState();
}

class _PrivateHospitalsScreenState extends State<PrivateHospitalsScreen> {
  final _searchController = TextEditingController();

  final List<String> _serviceFilters = const [
    'طوارئ 24 ساعة',
    'أشعة',
    'معمل',
    'أطفال',
    'تأمين',
  ];

  final Set<String> _selectedServices = <String>{};

  late final List<HospitalModel> _allHospitals = <HospitalModel>[
    const HospitalModel(
      id: 'alshifa',
      name: 'مستشفى الشفا',
      // ملاحظة: املأ البيانات الفعلية لاحقاً (العنوان/الهاتف/الموقع)
      address: null,
      phone: null,
      latitude: null,
      longitude: null,
      rating: null,
      ratingCount: null,
      services: <String>['طوارئ 24 ساعة', 'أشعة', 'معمل'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HospitalModel> get _filtered {
    final q = _searchController.text.trim();

    return _allHospitals.where((h) {
      final matchesText =
          q.isEmpty ||
          h.name.contains(q) ||
          (h.address != null && h.address!.contains(q));

      final matchesServices =
          _selectedServices.isEmpty ||
          _selectedServices.every((s) => h.services.contains(s));

      return matchesText && matchesServices;
    }).toList();
  }

  void _openDetails(HospitalModel hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalDetailsScreen(hospital: hospital),
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
        appBar: AppBar(title: const Text('مستشفيات خاصة')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المستشفى أو المنطقة',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
              ),
            ),
            SizedBox(
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
            ),
            const SizedBox(height: 8),
            Expanded(
              child: hospitals.isEmpty
                  ? const Center(child: Text('لا توجد نتائج مطابقة.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      itemCount: hospitals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final h = hospitals[index];
                        return _HospitalCard(
                          hospital: h,
                          onTap: () => _openDetails(h),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital, required this.onTap});

  final HospitalModel hospital;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: colorScheme.primary.withValues(alpha: 0.2),
        highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hospital.address?.trim().isNotEmpty == true
                            ? hospital.address!.trim()
                            : 'العنوان غير متوفر',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      if (hospital.services.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: hospital.services
                              .take(3)
                              .map(
                                (s) => Chip(
                                  label: Text(
                                    s,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  side: BorderSide(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_left, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
