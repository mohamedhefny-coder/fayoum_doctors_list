import 'package:flutter/material.dart';

import '../models/clinic_working_hours.dart';
import '../services/doctor_database_service.dart';

class ClinicWorkingHoursScheduleScreen extends StatefulWidget {
  const ClinicWorkingHoursScheduleScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
    this.initialNotes,
  });

  final String clinicId;
  final String clinicName;
  final String? initialNotes;

  @override
  State<ClinicWorkingHoursScheduleScreen> createState() =>
      _ClinicWorkingHoursScheduleScreenState();
}

class _ClinicWorkingHoursScheduleScreenState
    extends State<ClinicWorkingHoursScheduleScreen> {
  final _dbService = DoctorDatabaseService();
  final _notesController = TextEditingController();

  final List<String> _weekDays = const [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  final List<bool> _dayEnabled = List<bool>.filled(7, false);
  final List<TimeOfDay?> _dayStart = List<TimeOfDay?>.filled(7, null);
  final List<TimeOfDay?> _dayEnd = List<TimeOfDay?>.filled(7, null);

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.initialNotes ?? '';
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _dbService.getClinicWorkingHours(
        clinicId: widget.clinicId,
      );

      for (final row in rows) {
        if (row.dayOfWeek >= 0 && row.dayOfWeek < 7) {
          setState(() {
            _dayEnabled[row.dayOfWeek] = row.isEnabled;
            _dayStart[row.dayOfWeek] = row.startTime;
            _dayEnd[row.dayOfWeek] = row.endTime;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المواعيد: $e')));
    }
  }

  Future<void> _save() async {
    try {
      final entries = <ClinicWorkingHours>[];
      for (var i = 0; i < 7; i++) {
        entries.add(
          ClinicWorkingHours(
            clinicId: widget.clinicId,
            dayOfWeek: i,
            isEnabled: _dayEnabled[i],
            startTime: _dayStart[i],
            endTime: _dayEnd[i],
          ),
        );
      }

      await _dbService.upsertClinicWorkingHours(
        clinicId: widget.clinicId,
        entries: entries,
      );

      await _dbService.updateClinicWorkingHoursNotes(
        clinicId: widget.clinicId,
        notes: _notesController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ جدول المواعيد بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ المواعيد: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String fmt(TimeOfDay? t) {
      if (t == null) return '--:--';
      int hour = t.hour;
      String period = 'ص';
      if (hour >= 12) {
        period = 'م';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      final hh = hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm $period';
    }

    Future<void> pickStart(int i) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: _dayStart[i] ?? const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(alwaysUse24HourFormat: false),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
      );
      if (picked == null) return;
      setState(() => _dayStart[i] = picked);
    }

    Future<void> pickEnd(int i) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: _dayEnd[i] ?? const TimeOfDay(hour: 17, minute: 0),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(alwaysUse24HourFormat: false),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
      );
      if (picked == null) return;
      setState(() => _dayEnd[i] = picked);
    }

    final btnStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('جدول مواعيد: ${widget.clinicName}'),
          backgroundColor: const Color(0xFF246BCE),
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF246BCE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF246BCE)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'فعّل الأيام وحدد مواعيد البداية والنهاية لكل يوم.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...List<Widget>.generate(7, (i) {
                final enabled = _dayEnabled[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _weekDays[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: enabled,
                            onChanged: (v) =>
                                setState(() => _dayEnabled[i] = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: enabled ? () => pickStart(i) : null,
                              style: btnStyle,
                              child: Text('بداية: ${fmt(_dayStart[i])}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: enabled ? () => pickEnd(i) : null,
                              style: btnStyle,
                              child: Text('نهاية: ${fmt(_dayEnd[i])}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'ملاحظات (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'مثال: الحضور قبل الموعد بـ 15 دقيقة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BCE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
