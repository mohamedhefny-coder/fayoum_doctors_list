import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/doctor_database_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final _db = DoctorDatabaseService();

  late final TabController _tabController;

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _pending = const [];
  List<Map<String, dynamic>> _accepted = const [];
  List<Map<String, dynamic>> _rejected = const [];

  String? _resolvedDoctorId;

  String? get _authUserId => Supabase.instance.client.auth.currentUser?.id;

  String _shortId(String? id) {
    if (id == null || id.trim().isEmpty) return '-';
    final s = id.trim();
    return s.length <= 10
        ? s
        : '${s.substring(0, 6)}…${s.substring(s.length - 4)}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString();
    if (s.trim().isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.toLocal();
    return '${dd.year}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')}';
  }

  String _fmtTime(dynamic timeValue) {
    if (timeValue == null) return '-';
    final s = timeValue.toString();
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length >= 2) {
        final hh = parts[0].padLeft(2, '0');
        final mm = parts[1].padLeft(2, '0');
        return '$hh:$mm';
      }
    }
    return s;
  }

  Future<void> _fetchAll() async {
    final authUserId = _authUserId;
    if (authUserId == null) {
      setState(() {
        _error = 'يجب تسجيل الدخول كطبيب أولاً.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Validate doctor profile/id mapping (doctors.id should equal auth.uid()).
      // If there's a mismatch, `ensureCurrentDoctorProfile` throws a clear fix message.
      final doctor = await _db.ensureCurrentDoctorProfile();
      final doctorId = doctor.id;
      _resolvedDoctorId = doctorId;

      final pending = await _db.getAppointmentsForDoctor(
        doctorId: doctorId,
        status: DoctorDatabaseService.appointmentStatusPending,
      );
      final accepted = await _db.getAppointmentsForDoctor(
        doctorId: doctorId,
        status: DoctorDatabaseService.appointmentStatusAccepted,
      );
      final rejected = await _db.getAppointmentsForDoctor(
        doctorId: doctorId,
        status: DoctorDatabaseService.appointmentStatusRejected,
      );

      if (!mounted) return;
      setState(() {
        _pending = pending;
        _accepted = accepted;
        _rejected = rejected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setStatus({
    required Map<String, dynamic> appt,
    required String status,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final apptId =
        appt['id'] ?? appt['appointment_id'] ?? appt['appointmentId'];
    if (apptId == null) {
      debugPrint(
        'DoctorAppointments: missing appointment id. keys=${appt.keys.toList()}',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر تنفيذ الإجراء: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('DoctorAppointments: _setStatus status=$status id=$apptId');

    // نافذة حوارية متقدمة للقبول أو الحجز مكتمل
    if (status == DoctorDatabaseService.appointmentStatusAccepted) {
      await _showAcceptDialog(appt);
    } else {
      // الحجز مكتمل (مع اقتراح موعد بديل)
      await _showBookingFullDialog(appt);
    }
  }

  Future<void> _showAcceptDialog(Map<String, dynamic> appt) async {
    final messenger = ScaffoldMessenger.of(context);
    final apptId =
        appt['id'] ?? appt['appointment_id'] ?? appt['appointmentId'];
    if (apptId == null) {
      debugPrint(
        'DoctorAppointments: _showAcceptDialog missing id. keys=${appt.keys.toList()}',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح نافذة القبول: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('DoctorAppointments: opening accept dialog id=$apptId');
    final currentDate = _parseDate(appt['appointment_date']);
    final currentTime = _fmtTime(appt['appointment_time']);

    TimeOfDay? selectedTime;
    String? customTime;

    final notesController = TextEditingController();

    bool? confirmed;
    var notes = '';
    try {
      confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('قبول طلب الحجز'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الموعد المطلوب: ${_fmtDate(currentDate)} - $currentTime',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text('اقتراح ساعة محددة (في نفس اليوم):'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: dialogContext,
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      selectedTime = time;
                                      customTime =
                                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  selectedTime != null
                                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'اختر الوقت',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (selectedTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'سيتم تحديد الموعد: ${_fmtDate(currentDate)} - $customTime',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات للمريض (اختياري)',
                            hintText:
                                'مثال: يرجى الحضور قبل الموعد بـ 10 دقائق',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('قبول'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      notes = notesController.text.trim();
    } finally {
      notesController.dispose();
    }

    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _db.updateAppointmentWithDoctorResponse(
        appointmentId: apptId,
        status: DoctorDatabaseService.appointmentStatusAccepted,
        responseMessage: notes.isNotEmpty ? notes : null,
        suggestedTime: customTime,
      );
      await _fetchAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showBookingFullDialog(Map<String, dynamic> appt) async {
    final messenger = ScaffoldMessenger.of(context);
    final apptId =
        appt['id'] ?? appt['appointment_id'] ?? appt['appointmentId'];
    if (apptId == null) {
      debugPrint(
        'DoctorAppointments: _showBookingFullDialog missing id. keys=${appt.keys.toList()}',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح نافذة الحجز مكتمل: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('DoctorAppointments: opening booking full dialog id=$apptId');

    final messageController = TextEditingController();
    DateTime? suggestedDate;
    TimeOfDay? suggestedTime;

    var message = '';

    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('الحجز مكتمل'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('يمكنك كتابة ملاحظات واقتراح موعد بديل:'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات للمريض (اختياري)',
                            hintText:
                                'مثال: الحجز مكتمل لهذا اليوم، نقترح الموعد التالي',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'اقتراح موعد بديل (اختياري):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    builder: (context, child) {
                                      return Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      suggestedDate = date;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  suggestedDate != null
                                      ? _fmtDate(suggestedDate)
                                      : 'اختر التاريخ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: suggestedDate == null
                                    ? null
                                    : () async {
                                        final time = await showTimePicker(
                                          context: dialogContext,
                                          initialTime: TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (time != null) {
                                          setDialogState(() {
                                            suggestedTime = time;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  suggestedTime != null
                                      ? '${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'الوقت',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (suggestedDate != null && suggestedTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'الموعد البديل: ${_fmtDate(suggestedDate)} - ${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e, st) {
      debugPrint(
        'DoctorAppointments: show booking full dialog failed: $e\n$st',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فتح نافذة الحجز مكتمل: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } finally {
      message = messageController.text.trim();
      messageController.dispose();
    }

    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? suggestedTimeStr;
      if (suggestedTime != null) {
        suggestedTimeStr =
            '${suggestedTime!.hour.toString().padLeft(2, '0')}:${suggestedTime!.minute.toString().padLeft(2, '0')}:00';
      }

      await _db.updateAppointmentWithDoctorResponse(
        appointmentId: apptId,
        status: DoctorDatabaseService.appointmentStatusRejected,
        responseMessage: message.isNotEmpty ? message : null,
        suggestedDate: suggestedDate,
        suggestedTime: suggestedTimeStr,
      );
      await _fetchAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الحجز كمكتمل وإرسال الرد'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required bool isPending,
  }) {
    if (items.isEmpty) {
      final authId = _authUserId;
      final doctorId = _resolvedDoctorId;
      final hint =
          'لا توجد طلبات.\n'
          'إذا كنت متأكد أن هناك حجوزات تم إرسالها، تأكد من تسجيل الدخول بنفس حساب الطبيب، '
          'وأن doctors.id يساوي auth.uid() (راجع ملف fix_doctor_id_mismatch.sql).\n\n'
          'Auth: ${_shortId(authId)}\n'
          'Doctor: ${_shortId(doctorId)}';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appt = items[index];
          final date = _parseDate(appt['appointment_date']);
          final timeStr = _fmtTime(appt['appointment_time']);
          final patientName = (appt['patient_name'] ?? '').toString();
          final patientPhone = (appt['patient_phone'] ?? '').toString();
          final notes = (appt['notes'] ?? '').toString().trim();

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
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
                    Text(
                      '${_fmtDate(date)} • $timeStr',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'قيد المراجعة',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  patientName.isNotEmpty ? patientName : 'مريض',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  patientPhone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () async {
                                  assert(() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'DEBUG: تم الضغط على قبول',
                                        ),
                                        duration: Duration(milliseconds: 900),
                                      ),
                                    );
                                    return true;
                                  }());
                                  await _setStatus(
                                    appt: appt,
                                    status: DoctorDatabaseService
                                        .appointmentStatusAccepted,
                                  );
                                },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('قبول'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () async {
                                  assert(() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'DEBUG: تم الضغط على الحجز مكتمل',
                                        ),
                                        duration: Duration(milliseconds: 900),
                                      ),
                                    );
                                    return true;
                                  }());
                                  await _setStatus(
                                    appt: appt,
                                    status: DoctorDatabaseService
                                        .appointmentStatusRejected,
                                  );
                                },
                          icon: const Icon(Icons.event_busy),
                          label: const Text('الحجز مكتمل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة الحجز'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'قيد المراجعة (${_pending.length})'),
              Tab(text: 'مقبولة (${_accepted.length})'),
              Tab(text: 'مرفوضة (${_rejected.length})'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _fetchAll,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_pending, isPending: true),
                  _buildList(_accepted, isPending: false),
                  _buildList(_rejected, isPending: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
