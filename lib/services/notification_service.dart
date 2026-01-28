import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medication_reminders';
  static const String _channelName = 'تذكير الأدوية';
  static const String _channelDescription =
      'تنبيهات لتذكير بمواعيد جرعات الدواء';

  static const String _doctorChannelId = 'doctor_events';
  static const String _doctorChannelName = 'إشعارات الطبيب';
  static const String _doctorChannelDescription =
      'إشعارات عن الطلبات وإيصالات الدفع وتأكيد المواعيد المقترحة';

    static const String _adminChannelId = 'admin_events';
    static const String _adminChannelName = 'إشعارات المدير';
    static const String _adminChannelDescription =
      'إشعارات عن ردود الأطباء وطلبات النشر والرسائل';

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'فتح الإشعار',
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      linux: linuxInit,
    );

    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  static Future<void> showDoctorEvent({
    required String title,
    required String body,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    const androidDetails = AndroidNotificationDetails(
      _doctorChannelId,
      _doctorChannelName,
      channelDescription: _doctorChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> showAdminEvent({
    required String title,
    required String body,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    const androidDetails = AndroidNotificationDetails(
      _adminChannelId,
      _adminChannelName,
      channelDescription: _adminChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> scheduleDailyMedicationReminder({
    required int notificationId,
    required String medicineName,
    required TimeOfDay time,
  }) async {
    final scheduledDate = _nextInstanceOfTime(time);

    await _scheduleAt(
      notificationId: notificationId,
      title: 'تذكير الدواء',
      body: 'حان موعد جرعة: $medicineName',
      scheduledDate: scheduledDate,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleMedicationAtDateTime({
    required int notificationId,
    required String medicineName,
    required DateTime dateTime,
  }) async {
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    await _scheduleAt(
      notificationId: notificationId,
      title: 'تذكير الدواء',
      body: 'حان موعد جرعة: $medicineName',
      scheduledDate: scheduledDate,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> _scheduleAt({
    required int notificationId,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents? matchDateTimeComponents,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  static Future<void> cancel(int notificationId) =>
      _plugin.cancel(notificationId);

  static Future<void> cancelMany(Iterable<int> notificationIds) async {
    for (final id in notificationIds) {
      await _plugin.cancel(id);
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
