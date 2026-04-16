import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/fayoum_locations.dart';
import '../services/doctor_database_service.dart';
import 'clinic_working_hours_schedule_screen.dart';

class DoctorClinicsScreen extends StatefulWidget {
  const DoctorClinicsScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<DoctorClinicsScreen> createState() => _DoctorClinicsScreenState();
}

class _DoctorClinicsScreenState extends State<DoctorClinicsScreen> {
  final _db = DoctorDatabaseService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _clinics = const <Map<String, dynamic>>[];

  Future<void> _openClinicSchedule(Map<String, dynamic> clinic) async {
    final id = (clinic['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    final name = (clinic['clinic_name'] ?? 'عيادة').toString().trim();
    final notes = (clinic['working_hours_notes'] ?? '').toString();

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicWorkingHoursScheduleScreen(
          clinicId: id,
          clinicName: name.isEmpty ? 'عيادة' : name,
          initialNotes: notes,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _db.getDoctorClinics(doctorId: widget.doctorId);
      if (!mounted) return;
      setState(() {
        _clinics = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openMapsSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح خرائط Google.')));
    }
  }

  ({double lat, double lng})? _tryParseLatLngFromText(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    // 1) @lat,lng
    final atMatch = RegExp(
      r'@\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(t);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1) ?? '');
      final lng = double.tryParse(atMatch.group(2) ?? '');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    // 2) query=lat,lng or q=lat,lng
    final qMatch = RegExp(
      r'(?:query|q)=\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(t);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1) ?? '');
      final lng = double.tryParse(qMatch.group(2) ?? '');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    // 3) Plain "lat,lng"
    final plain = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(t);
    if (plain != null) {
      final lat = double.tryParse(plain.group(1) ?? '');
      final lng = double.tryParse(plain.group(2) ?? '');
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    return null;
  }

  Future<void> _pickGeoLocationFromGoogleMaps({
    required TextEditingController geoCtrl,
    required void Function(VoidCallback fn) dialogSetState,
    required String fallbackQuery,
  }) async {
    try {
      final clip = await Clipboard.getData('text/plain');
      final text = (clip?.text ?? '').trim();
      final coords = _tryParseLatLngFromText(text);
      if (coords != null) {
        dialogSetState(() {
          geoCtrl.text = '${coords.lat},${coords.lng}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الموقع من الحافظة بنجاح')),
          );
        }
        return;
      }

      await _openMapsSearch(fallbackQuery);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'افتح خرائط Google وحدد الموقع ثم "مشاركة" → "نسخ الرابط/الإحداثيات".\nثم ارجع واضغط زر اختيار الموقع مرة أخرى.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر قراءة الحافظة. يمكنك إدخال الإحداثيات يدوياً.'),
        ),
      );
    }
  }

  Future<void> _showClinicDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(
      text: (existing?['clinic_name'] ?? '').toString(),
    );
    final addressCtrl = TextEditingController(
      text: (existing?['address'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (existing?['phone'] ?? '').toString(),
    );
    final geoCtrl = TextEditingController(
      text: (existing?['geo_location'] ?? '').toString(),
    );

    String? selectedCenter = (existing?['center'] ?? '').toString().trim();
    if (selectedCenter.isEmpty) {
      selectedCenter = null;
    } else if (!fayoumCenters.contains(selectedCenter)) {
      selectedCenter = null;
    }

    final isEdit = existing != null;

    String buildFallbackQuery() {
      final parts = <String>[];
      final c = (selectedCenter ?? '').trim();
      final a = addressCtrl.text.trim();
      if (c.isNotEmpty) parts.add(c);
      if (a.isNotEmpty) parts.add(a);
      return parts.isEmpty ? 'الفيوم، مصر' : parts.join('، ');
    }

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, dialogSetState) {
              final hasGeo = geoCtrl.text.trim().isNotEmpty;

              return AlertDialog(
                title: Text(isEdit ? 'تعديل العيادة' : 'إضافة عيادة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم العيادة (اختياري)',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedCenter,
                        items: fayoumCenters
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  c,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedCenter = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'المدينة / المركز',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressCtrl,
                        onChanged: (_) => dialogSetState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'العنوان التفصيلي',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'الموقع الجغرافي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (hasGeo)
                            TextButton.icon(
                              onPressed: () => _openMapsSearch(geoCtrl.text),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('عرض'),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                geoCtrl.text.trim().isEmpty
                                    ? 'اضغط لاختيار موقع العيادة من خرائط Google'
                                    : geoCtrl.text.trim(),
                                style: TextStyle(
                                  color: geoCtrl.text.trim().isEmpty
                                      ? Colors.grey
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _pickGeoLocationFromGoogleMaps(
                                  geoCtrl: geoCtrl,
                                  dialogSetState: dialogSetState,
                                  fallbackQuery: buildFallbackQuery(),
                                );
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('اختيار'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BCD4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: geoCtrl,
                        onChanged: (_) => dialogSetState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'الإحداثيات (lat,lng) - اختياري',
                          prefixIcon: Icon(Icons.pin_drop_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'هاتف العيادة (اختياري)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != true) return;

      final center = (selectedCenter ?? '').trim();

      if (isEdit) {
        final id = (existing['id'] ?? '').toString();
        await _db.updateClinic(
          clinicId: id,
          clinicName: nameCtrl.text,
          center: center,
          address: addressCtrl.text,
          geoLocation: geoCtrl.text,
          phone: phoneCtrl.text,
        );
      } else {
        await _db.createClinic(
          doctorId: widget.doctorId,
          clinicName: nameCtrl.text,
          center: center,
          address: addressCtrl.text,
          geoLocation: geoCtrl.text,
          phone: phoneCtrl.text,
        );
      }

      if (!mounted) return;
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم تحديث العيادة' : 'تم إضافة العيادة'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      nameCtrl.dispose();
      addressCtrl.dispose();
      phoneCtrl.dispose();
      geoCtrl.dispose();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> clinic) async {
    final id = (clinic['id'] ?? '').toString();
    final name = (clinic['clinic_name'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف العيادة'),
          content: Text('هل تريد حذف "$name"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _db.deleteClinic(clinicId: id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحذف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _clinicCard(Map<String, dynamic> clinic) {
    final name = (clinic['clinic_name'] ?? '').toString().trim();
    final center = (clinic['center'] ?? '').toString().trim();
    final address = (clinic['address'] ?? '').toString().trim();
    final geo = (clinic['geo_location'] ?? '').toString().trim();
    final phone = (clinic['phone'] ?? '').toString().trim();

    final mapsQuery = geo.isNotEmpty
        ? geo
        : [center, address].where((s) => s.trim().isNotEmpty).join('، ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'عيادة' : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (center.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'المواعيد',
                onPressed: () => _openClinicSchedule(clinic),
                icon: const Icon(Icons.schedule_outlined),
              ),
              IconButton(
                tooltip: 'تعديل',
                onPressed: () => _showClinicDialog(existing: clinic),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => _confirmDelete(clinic),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.25,
                  ),
                ),
              ),
              TextButton(
                onPressed: mapsQuery.trim().isEmpty
                    ? null
                    : () => _openMapsSearch(mapsQuery),
                child: const Text('خرائط'),
              ),
            ],
          ),
          if (phone.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العيادات'),
          actions: [
            IconButton(
              tooltip: 'إضافة',
              onPressed: () => _showClinicDialog(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 24),
                    Center(child: Text('تعذر تحميل العيادات: $_error')),
                  ],
                )
              : _clinics.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 24),
                    Center(child: Text('لا يوجد عيادات إضافية حالياً.')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clinics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _clinicCard(_clinics[index]),
                ),
        ),
      ),
    );
  }
}
