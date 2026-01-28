import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../models/doctor_working_hours.dart';
import '../services/doctor_database_service.dart';

class WorkingHoursScheduleScreen extends StatefulWidget {
  final Doctor doctor;

  const WorkingHoursScheduleScreen({super.key, required this.doctor});

  @override
  State<WorkingHoursScheduleScreen> createState() =>
      _WorkingHoursScheduleScreenState();
}

class _WorkingHoursScheduleScreenState
    extends State<WorkingHoursScheduleScreen> {
  final _dbService = DoctorDatabaseService();
  final _workingHoursNotesController = TextEditingController();

  final List<String> _weekDays = [
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
    _workingHoursNotesController.text =
        widget.doctor.workingHoursNotes ?? '';
    _loadWorkingHours();
  }

  @override
  void dispose() {
    _workingHoursNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkingHours() async {
    try {
      final rows =
          await _dbService.getDoctorWorkingHours(doctorId: widget.doctor.id);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المواعيد: $e')),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    try {
      // إنشاء قائمة بمواعيد العمل
      final entries = <DoctorWorkingHours>[];
      for (int i = 0; i < 7; i++) {
        entries.add(
          DoctorWorkingHours(
            doctorId: widget.doctor.id,
            dayOfWeek: i,
            isEnabled: _dayEnabled[i],
            startTime: _dayStart[i],
            endTime: _dayEnd[i],
          ),
        );
      }

      // حفظ مواعيد العمل
      await _dbService.upsertDoctorWorkingHours(
        doctorId: widget.doctor.id,
        entries: entries,
      );

      // حفظ ملاحظات المواعيد
      await _dbService.updateDoctorProfile(
        doctorId: widget.doctor.id,
        workingHoursNotes: _workingHoursNotesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ جدول المواعيد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ المواعيد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول مواعيد العيادة'),
          backgroundColor: const Color(0xFF246BCE),
          foregroundColor: Colors.white,
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
                        'قم بتفعيل الأيام التي تعمل فيها وحدد مواعيد البداية والنهاية لكل يوم',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...List<Widget>.generate(7, (i) {
                final enabled = _dayEnabled[i];
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

                Future<void> pickStart() async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _dayStart[i] ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked == null) return;
                  setState(() => _dayStart[i] = picked);
                }

                Future<void> pickEnd() async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _dayEnd[i] ?? const TimeOfDay(hour: 17, minute: 0),
                  );
                  if (picked == null) return;
                  setState(() => _dayEnd[i] = picked);
                }

                final btnStyle = OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _weekDays[i],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: (v) {
                          setState(() {
                            _dayEnabled[i] = v;
                            if (!v) {
                              _dayStart[i] = null;
                              _dayEnd[i] = null;
                            }
                          });
                        },
                        activeThumbColor: const Color(0xFF246BCE),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: enabled ? pickStart : null,
                        style: btnStyle,
                        child: Text('من ${fmt(_dayStart[i])}'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: enabled ? pickEnd : null,
                        style: btnStyle,
                        child: Text('إلى ${fmt(_dayEnd[i])}'),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF246BCE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ملاحظات على المواعيد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _workingHoursNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD700),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD700),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF246BCE),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'مثال: الحجز مسبقاً / الطوارئ حسب المتاح',
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BCE),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'حفظ جدول المواعيد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
