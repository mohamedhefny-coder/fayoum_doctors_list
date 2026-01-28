import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/doctor_model.dart';
import '../services/doctor_database_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  static const _prefsPhoneKey = 'my_appointments_phone';

  final _db = DoctorDatabaseService();
  final _phoneController = TextEditingController();

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _appointments = const [];
  Map<String, Doctor> _doctorsById = const {};

  @override
  void initState() {
    super.initState();
    _loadSavedPhoneAndFetch();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPhoneAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsPhoneKey) ?? '';
    if (saved.trim().isNotEmpty) {
      _phoneController.text = saved;
      await _fetch();
    }
  }

  Future<void> _savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPhoneKey, phone);
  }

  Future<void> _fetch() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _appointments = const [];
        _doctorsById = const {};
        _error = 'يرجى إدخال رقم الهاتف لعرض المواعيد.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _savePhone(phone);
      final rows = await _db.getAppointmentsByPatientPhone(patientPhone: phone);
      final doctorIds = rows
          .map((e) => (e['doctor_id'] ?? '').toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final doctors = await _db.getDoctorsByIds(doctorIds: doctorIds);

      if (!mounted) return;
      setState(() {
        _appointments = rows;
        _doctorsById = doctors;
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

  Color _statusColor(String status) {
    switch (status) {
      case DoctorDatabaseService.appointmentStatusAccepted:
        return AppColors.success;
      case DoctorDatabaseService.appointmentStatusRejected:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case DoctorDatabaseService.appointmentStatusAccepted:
        return 'تم القبول';
      case DoctorDatabaseService.appointmentStatusRejected:
        return 'تم الرفض';
      default:
        return 'قيد المراجعة';
    }
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

  bool _doctorRequiresPayAtBooking(Doctor? doctor) {
    if (doctor == null) return false;
    return doctor.isPayAtBookingEnabled &&
        (doctor.paymentMethod ?? '').trim().isNotEmpty;
  }

  Future<void> _uploadReceipt({
    required Map<String, dynamic> appt,
    required Doctor doctor,
  }) async {
    final apptId = appt['id'];
    if (apptId == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = await _db.uploadPaymentReceipt(imageFile: File(picked.path));
      await _db.updateAppointmentPaymentReceiptUrl(
        appointmentId: apptId,
        paymentReceiptUrl: url,
      );
      await _fetch();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم رفع الإيصال بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر رفع الإيصال: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptSuggestedSlotAndResubmit(
    Map<String, dynamic> appt,
  ) async {
    final status = (appt['status'] ?? '').toString();
    final hasSuggestion =
        appt['suggested_date'] != null ||
        (appt['suggested_time'] != null &&
            appt['suggested_time'].toString().trim().isNotEmpty);
    if (status != DoctorDatabaseService.appointmentStatusRejected ||
        !hasSuggestion) {
      return;
    }

    final suggestedDate = _parseDate(appt['suggested_date']);
    final suggestedTime = appt['suggested_time'];
    final suggestedLabel =
        '${_fmtDate(suggestedDate)} • ${_fmtTime(suggestedTime)}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الموعد المقترح'),
            content: Text(
              'هل تريد الموافقة على الموعد المقترح من الطبيب وإعادة إرسال الطلب؟\n\n$suggestedLabel',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('موافقة وإعادة الإرسال'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _db.resubmitAppointmentWithSuggestedSlot(appointment: appt);
      await _fetch();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تمت الموافقة وإعادة إرسال الطلب'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر إعادة الإرسال: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPaymentMethodsCard(Doctor doctor) {
    final methods = (doctor.paymentMethod ?? '').split(',');
    final accounts = (doctor.paymentAccount ?? '').split(',');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'طرق الدفع المتاحة:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(methods.length, (i) {
            if (i >= accounts.length) return const SizedBox.shrink();
            final method = methods[i].trim();
            final account = accounts[i].trim();
            if (method.isEmpty || account.isEmpty) {
              return const SizedBox.shrink();
            }

            IconData icon;
            String label;
            Color color;

            if (method == 'vodafone_cash') {
              icon = Icons.phone_android;
              label = 'فودافون كاش';
              color = const Color(0xFFE60000);
            } else if (method == 'instapay') {
              icon = Icons.account_balance_wallet;
              label = 'انستا باي';
              color = const Color(0xFF00A651);
            } else {
              icon = Icons.payments_outlined;
              label = method;
              color = AppColors.textSecondary;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
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
          title: const Text('مواعيدي'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _fetch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _fetch,
                      icon: const Icon(Icons.search),
                      label: const Text('عرض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Container(
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _appointments.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد طلبات حجز بعد.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.separated(
                          itemCount: _appointments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final appt = _appointments[index];
                            final status = (appt['status'] ?? '')
                                .toString()
                                .trim();
                            final doctorId = (appt['doctor_id'] ?? '')
                                .toString();
                            final doctor = _doctorsById[doctorId];

                            final date = _parseDate(appt['appointment_date']);
                            final timeStr = _fmtTime(appt['appointment_time']);
                            final receiptUrl =
                                (appt['payment_receipt_url'] ?? '').toString();
                            final isPaymentConfirmed =
                                appt['payment_confirmed'] == true;

                            final requiresPayment = _doctorRequiresPayAtBooking(
                              doctor,
                            );

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.25),
                                ),
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            status,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${_fmtDate(date)} • $timeStr',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    doctor?.fullName.isNotEmpty == true
                                        ? doctor!.fullName
                                        : 'الطبيب: $doctorId',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'المريض: ${(appt['patient_name'] ?? '').toString()} — ${(appt['patient_phone'] ?? '').toString()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if ((appt['notes'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        (appt['notes'] ?? '').toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  // عرض رد الطبيب والموعد المقترح
                                  if ((appt['doctor_response_message'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            status ==
                                                DoctorDatabaseService
                                                    .appointmentStatusRejected
                                            ? Colors.orange.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.blue.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              status ==
                                                  DoctorDatabaseService
                                                      .appointmentStatusRejected
                                              ? Colors.orange
                                              : Colors.blue,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.message,
                                                color:
                                                    status ==
                                                        DoctorDatabaseService
                                                            .appointmentStatusRejected
                                                    ? Colors.orange
                                                    : Colors.blue,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'رد الطبيب:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            (appt['doctor_response_message'] ??
                                                    '')
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // عرض الموعد المقترح من الطبيب
                                  if (appt['suggested_date'] != null ||
                                      appt['suggested_time'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                color: AppColors.primary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'موعد مقترح من الطبيب:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (appt['suggested_date'] !=
                                                  null)
                                                Text(
                                                  _fmtDate(
                                                    _parseDate(
                                                      appt['suggested_date'],
                                                    ),
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              if (appt['suggested_date'] !=
                                                      null &&
                                                  appt['suggested_time'] !=
                                                      null)
                                                Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              if (appt['suggested_time'] !=
                                                  null)
                                                Text(
                                                  _fmtTime(
                                                    appt['suggested_time'],
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (status ==
                                          DoctorDatabaseService
                                              .appointmentStatusRejected &&
                                      (appt['suggested_date'] != null ||
                                          (appt['suggested_time'] != null &&
                                              appt['suggested_time']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty))) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _loading
                                            ? null
                                            : () =>
                                                  _acceptSuggestedSlotAndResubmit(
                                                    appt,
                                                  ),
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text(
                                          'موافقة على الموعد المقترح وإعادة إرسال الطلب',
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (status ==
                                          DoctorDatabaseService
                                              .appointmentStatusAccepted &&
                                      doctor != null) ...[
                                    const SizedBox(height: 12),
                                    if (requiresPayment) ...[
                                      // إذا تم تأكيد الدفع، نعرض رسالة التأكيد فقط
                                      if (isPaymentConfirmed)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF10B981),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF10B981),
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      '✓ تم تأكيد الدفع',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF10B981,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'قام الطبيب بتأكيد استلام الدفع. موعدك مؤكد.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      // إذا لم يتم تأكيد الدفع، نعرض طرق الدفع وزر رفع الإيصال
                                      else ...[
                                        _buildPaymentMethodsCard(doctor),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _loading
                                                    ? null
                                                    : () => _uploadReceipt(
                                                        appt: appt,
                                                        doctor: doctor,
                                                      ),
                                                icon: const Icon(
                                                  Icons.upload_file,
                                                ),
                                                label: Text(
                                                  receiptUrl.trim().isEmpty
                                                      ? 'رفع إيصال الدفع'
                                                      : 'تحديث إيصال الدفع',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (receiptUrl.trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.hourglass_empty,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'تم رفع الإيصال. في انتظار تأكيد الطبيب...',
                                                  style: TextStyle(
                                                    color:
                                                        Colors.orange.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ] else
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.success.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'تم قبول الطلب. الدفع سيتم في العيادة.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                  ] else if (status ==
                                          DoctorDatabaseService
                                              .appointmentStatusPending &&
                                      _doctorRequiresPayAtBooking(doctor))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        'ملاحظة: ستظهر طرق الدفع بعد قبول الطبيب للطلب.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
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
