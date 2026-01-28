import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Realtime + local notifications for admins.
///
/// Currently notifies on:
/// - New doctor replies to admin messages (admin_message_replies INSERT)
/// - New publish requests (doctors UPDATE where publish_requested becomes true)
///
/// Push notifications when the app is killed require FCM + server-side setup.
class AdminRealtimeNotificationsService {
  AdminRealtimeNotificationsService._();

  static RealtimeChannel? _channel;
  static String? _adminId;
  static bool _starting = false;

  static final Map<String, bool> _publishRequestedByDoctorId = {};
  static final Map<String, DateTime> _dedupe = {};

  static Future<void> startForCurrentAdmin() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    if (_adminId == user.id && _channel != null) {
      return;
    }

    if (_starting) return;
    _starting = true;
    try {
      await stop();
      _adminId = user.id;
      await _primeCache(adminId: user.id);
      _subscribe(adminId: user.id);
    } finally {
      _starting = false;
    }
  }

  static Future<void> stop() async {
    final ch = _channel;
    _channel = null;
    _adminId = null;
    _publishRequestedByDoctorId.clear();
    _dedupe.clear();

    if (ch != null) {
      try {
        await ch.unsubscribe();
      } catch (_) {
        // ignore
      }
    }
  }

  static Future<void> _primeCache({required String adminId}) async {
    final client = Supabase.instance.client;
    try {
      final rows = await client
          .from('doctors')
          .select('id,publish_requested') as List<dynamic>;

      for (final r in rows.whereType<Map<String, dynamic>>()) {
        final id = (r['id'] ?? '').toString();
        if (id.isEmpty) continue;
        _publishRequestedByDoctorId[id] = r['publish_requested'] == true;
      }
    } catch (_) {
      // Cache is only for dedupe. If it fails, we still subscribe.
    }
  }

  static void _subscribe({required String adminId}) {
    final client = Supabase.instance.client;
    final channel = client.channel('admin_events_$adminId');

    // 1) New doctor reply
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'admin_message_replies',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'admin_id',
        value: adminId,
      ),
      callback: (payload) => _handleNewReply(payload.newRecord),
    );

    // 2) Publish request (doctor updates publish_requested -> true)
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'doctors',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'publish_requested',
        value: true,
      ),
      callback: (payload) => _handleDoctorUpdate(payload.newRecord),
    );

    channel.subscribe();
    _channel = channel;
  }

  static void _handleNewReply(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    if (id.isEmpty) return;

    final reply = (record['reply'] ?? '').toString().trim();
    _notifyOnce(
      key: 'reply:$id:${record['created_at'] ?? ''}',
      title: 'رد جديد من طبيب',
      body: reply.isNotEmpty ? reply : 'تم استلام رد جديد',
    );
  }

  static void _handleDoctorUpdate(Map<String, dynamic> record) {
    final doctorId = (record['id'] ?? '').toString();
    if (doctorId.isEmpty) return;

    final requested = record['publish_requested'] == true;
    final prev = _publishRequestedByDoctorId[doctorId];

    // Fire only on transition false -> true
    if (requested && prev != true) {
      final name = (record['full_name'] ?? '').toString().trim();
      _notifyOnce(
        key: 'publish_request:$doctorId:${record['updated_at'] ?? record['created_at'] ?? ''}',
        title: 'طلب نشر جديد',
        body: name.isNotEmpty
            ? 'الطبيب $name طلب نشر حسابه'
            : 'تم استلام طلب نشر جديد',
      );
    }

    _publishRequestedByDoctorId[doctorId] = requested;
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

    unawaited(NotificationService.showAdminEvent(title: title, body: body));
  }

  static void _purgeDedupe() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    _dedupe.removeWhere((_, ts) => ts.isBefore(cutoff));
  }
}
