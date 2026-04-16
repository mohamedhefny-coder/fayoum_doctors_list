import 'package:flutter/material.dart';

class ClinicWorkingHours {
  final String clinicId;
  final int dayOfWeek; // 0..6
  final bool isEnabled;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  const ClinicWorkingHours({
    required this.clinicId,
    required this.dayOfWeek,
    required this.isEnabled,
    required this.startTime,
    required this.endTime,
  });

  static TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    final parts = v.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  factory ClinicWorkingHours.fromJson(Map<String, dynamic> json) {
    return ClinicWorkingHours(
      clinicId: (json['clinic_id'] ?? '').toString(),
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
      isEnabled: (json['is_enabled'] as bool?) ?? false,
      startTime: _parseTime(json['start_time']?.toString()),
      endTime: _parseTime(json['end_time']?.toString()),
    );
  }

  Map<String, dynamic> toUpsertJson() => {
    'clinic_id': clinicId,
    'day_of_week': dayOfWeek,
    'is_enabled': isEnabled,
    'start_time': _formatTime(startTime),
    'end_time': _formatTime(endTime),
    'updated_at': DateTime.now().toIso8601String(),
  };
}
