import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmTtsService {
  AlarmTtsService._();

  static const MethodChannel _channel = MethodChannel('alarm_tts');

  static Future<void> scheduleDailyAlarm({
    required int requestCode,
    required String medicineName,
    required TimeOfDay time,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('scheduleDaily', {
      'requestCode': requestCode,
      'medicineName': medicineName,
      'hour': time.hour,
      'minute': time.minute,
    });
  }

  static Future<void> scheduleEveryNMonthsAlarm({
    required int requestCode,
    required String medicineName,
    required DateTime startDateTime,
    required int intervalMonths,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('scheduleEveryNMonths', {
      'requestCode': requestCode,
      'medicineName': medicineName,
      'startMillis': startDateTime.millisecondsSinceEpoch,
      'intervalMonths': intervalMonths,
    });
  }

  static Future<void> cancel(int requestCode) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('cancel', {
      'requestCode': requestCode,
    });
  }

  static Future<void> cancelMany(Iterable<int> requestCodes) async {
    if (!Platform.isAndroid) return;
    for (final code in requestCodes) {
      await cancel(code);
    }
  }
}
