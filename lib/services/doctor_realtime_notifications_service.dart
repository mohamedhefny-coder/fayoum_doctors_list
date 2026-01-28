import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'doctor_database_service.dart';
import 'notification_service.dart';

/// Realtime + local notifications for doctors.
///
/// This provides in-app notifications while the app is running (foreground or
/// background) using Supabase Realtime and flutter_local_notifications.
///
/// Push notifications when the app is killed require FCM + server-side setup.
class DoctorRealtimeNotificationsService {
  DoctorRealtimeNotificationsService._();

  static RealtimeChannel? _channel;
  static String? _doctorId;
  static bool _starting = false;

  static final Map<dynamic, String?> _statusByAppointmentId = {};
  static final Map<dynamic, String?> _receiptUrlByAppointmentId = {};
  static final Map<dynamic, String?> _notesByAppointmentId = {};

  static final Map<String, DateTime> _dedupe = {};

  static int _unseenCount = 0;
  static final StreamController<int> _unseenController =
      StreamController<int>.broadcast();

  static Stream<int> get notificationCountStream => _unseenController.stream;

  static bool? _wasPublished;

  static const String _suggestionAcceptedMarker =
      'تمت الموافقة على الموعد المقترح من الطبيب.';

  static Future<void> startForDoctor(String doctorId) async {
    final normalized = doctorId.trim();
    if (normalized.isEmpty) return;

    if (_doctorId == normalized && _channel != null) {
      return;
    }

    if (_starting) return;
    _starting = true;
    try {
      await stop();
      _doctorId = normalized;

      await _primeCache(doctorId: normalized);
      _subscribe(doctorId: normalized);
    } finally {
      _starting = false;
    }
  }

  static Future<void> stop() async {
    final ch = _channel;
    _channel = null;
    _doctorId = null;

    _statusByAppointmentId.clear();
    _receiptUrlByAppointmentId.clear();
    _notesByAppointmentId.clear();
    _dedupe.clear();
    _unseenCount = 0;
    if (!_unseenController.isClosed) {
      _unseenController.add(0);
    }
    _wasPublished = null;

    if (ch != null) {
      try {
        await ch.unsubscribe();
      } catch (_) {
        // ignore
      }
    }
  }

  static Future<void> _primeCache({required String doctorId}) async {
    final client = Supabase.instance.client;
    try {
      final rows =
          await client
                  .from('appointments')
                  .select('id,status,payment_receipt_url,notes')
                  .eq('doctor_id', doctorId)
              as List<dynamic>;

      for (final r in rows.whereType<Map<String, dynamic>>()) {
        final id = r['id'];
        if (id == null) continue;
        _statusByAppointmentId[id] = r['status']?.toString();
        _receiptUrlByAppointmentId[id] = r['payment_receipt_url']?.toString();
        _notesByAppointmentId[id] = r['notes']?.toString();
      }
    } catch (_) {
      // Cache is only for dedupe. If it fails, we still subscribe.
    }

    try {
      final doc =
          await client
                  .from('doctors')
                  .select('is_published')
                  .eq('id', doctorId)
                  .maybeSingle();
      if (doc is Map<String, dynamic>) {
        _wasPublished = doc['is_published'] == true;
      }
    } catch (_) {
      // ignore
    }
  }

  static void _subscribe({required String doctorId}) {
    final client = Supabase.instance.client;

    final channel = client.channel('doctor_appointments_$doctorId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (payload) => _handleInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (payload) => _handleUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (payload) => _handleNewAdminMessage(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'doctor_questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (payload) => _handleNewQuestion(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'doctors',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: doctorId,
          ),
          callback: (payload) => _handleDoctorRowUpdate(payload.newRecord),
        )
        .subscribe();

    _channel = channel;
  }

  static void _handleNewAdminMessage(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    if (id.isEmpty) return;
    final title = (record['title'] ?? 'رسالة من الإدارة').toString().trim();
    final body = (record['message'] ?? '').toString().trim();

    _notifyOnce(
      key: 'admin_msg:$id:${record['created_at'] ?? ''}',
      title: title.isNotEmpty ? title : 'رسالة من الإدارة',
      body: body.isNotEmpty ? body : 'لديك رسالة جديدة من الإدارة',
    );
  }

  static void _handleNewQuestion(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    if (id.isEmpty) return;
    final patient = (record['patient_name'] ?? '').toString().trim();
    final q = (record['question'] ?? '').toString().trim();

    _notifyOnce(
      key: 'q:$id:${record['created_at'] ?? ''}',
      title: 'سؤال جديد',
      body: patient.isNotEmpty
          ? '$patient: ${q.isNotEmpty ? q : 'سؤال جديد'}'
          : (q.isNotEmpty ? q : 'تم استلام سؤال جديد'),
    );
  }

  static void _handleDoctorRowUpdate(Map<String, dynamic> record) {
    final isPublished = record['is_published'] == true;
    final prev = _wasPublished;

    if (prev != true && isPublished) {
      _notifyOnce(
        key: 'published:${record['id'] ?? ''}:${record['published_at'] ?? record['updated_at'] ?? ''}',
        title: 'تم قبول النشر',
        body: 'تمت الموافقة على نشر حسابك',
      );
    }

    _wasPublished = isPublished;
  }

  static void _handleInsert(Map<String, dynamic> record) {
    final id =
        record['id'] ?? record['appointment_id'] ?? record['appointmentId'];
    if (id == null) return;

    final status = (record['status'] ?? '').toString();
    _statusByAppointmentId[id] = status;
    _receiptUrlByAppointmentId[id] = record['payment_receipt_url']?.toString();
    _notesByAppointmentId[id] = record['notes']?.toString();

    if (status == DoctorDatabaseService.appointmentStatusPending) {
      final patientName = (record['patient_name'] ?? '').toString().trim();
      final date = (record['appointment_date'] ?? '').toString();
      final time = (record['appointment_time'] ?? '').toString();

      _notifyOnce(
        key: 'new:$id:${record['created_at'] ?? ''}',
        title: 'طلب حجز جديد',
        body: patientName.isNotEmpty
            ? '$patientName — $date ${time.isNotEmpty ? time : ''}'.trim()
            : 'تم استلام طلب حجز جديد',
      );
    }
  }

  static void _handleUpdate(Map<String, dynamic> record) {
    final id =
        record['id'] ?? record['appointment_id'] ?? record['appointmentId'];
    if (id == null) return;

    final newStatus = (record['status'] ?? '').toString();
    final prevStatus = _statusByAppointmentId[id];

    final newReceiptUrl = (record['payment_receipt_url'] ?? '')
        .toString()
        .trim();
    final prevReceiptUrl = (_receiptUrlByAppointmentId[id] ?? '')
        .toString()
        .trim();

    final newNotes = (record['notes'] ?? '').toString();
    final prevNotes = (_notesByAppointmentId[id] ?? '').toString();

    // 1) Receipt uploaded
    if (newReceiptUrl.isNotEmpty && prevReceiptUrl.isEmpty) {
      final patientName = (record['patient_name'] ?? '').toString().trim();
      _notifyOnce(
        key: 'receipt:$id:${record['updated_at'] ?? newReceiptUrl}',
        title: 'تم رفع إيصال دفع',
        body: patientName.isNotEmpty
            ? 'قام $patientName برفع إيصال الدفع'
            : 'تم رفع إيصال الدفع لهذا الطلب',
      );
    }

    // 2) Patient accepted suggested slot and re-submitted
    if (prevStatus == DoctorDatabaseService.appointmentStatusRejected &&
        newStatus == DoctorDatabaseService.appointmentStatusPending) {
      final markerNow = newNotes.contains(_suggestionAcceptedMarker);
      final markerBefore = prevNotes.contains(_suggestionAcceptedMarker);
      if (markerNow && !markerBefore) {
        final patientName = (record['patient_name'] ?? '').toString().trim();
        _notifyOnce(
          key: 'resubmit:$id:${record['updated_at'] ?? ''}',
          title: 'تمت الموافقة على الموعد المقترح',
          body: patientName.isNotEmpty
              ? 'قام $patientName بالموافقة وإعادة إرسال الطلب'
              : 'قام المريض بالموافقة وإعادة إرسال الطلب',
        );
      }
    }

    _statusByAppointmentId[id] = newStatus;
    _receiptUrlByAppointmentId[id] = record['payment_receipt_url']?.toString();
    _notesByAppointmentId[id] = record['notes']?.toString();
  }

  static void _notifyOnce({
    required String key,
    required String title,
    required String body,
  }) {
    _purgeDedupe();
    final now = DateTime.now();

    if (_dedupe.containsKey(key)) return;
    _dedupe[key] = now;

    unawaited(NotificationService.showDoctorEvent(title: title, body: body));

    _unseenCount += 1;
    if (!_unseenController.isClosed) {
      _unseenController.add(_unseenCount);
    }
  }

  static void _purgeDedupe() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    _dedupe.removeWhere((_, ts) => ts.isBefore(cutoff));
  }

  static void markAllSeen() {
    _unseenCount = 0;
    if (!_unseenController.isClosed) {
      _unseenController.add(0);
    }
  }
}
