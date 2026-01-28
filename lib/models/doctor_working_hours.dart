import 'package:flutter/material.dart';

class DoctorWorkingHours {
  final String doctorId;
  final int dayOfWeek; // 0..6
  final bool isEnabled;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  const DoctorWorkingHours({
    required this.doctorId,
    required this.dayOfWeek,
    required this.isEnabled,
    required this.startTime,
    required this.endTime,
  });

  DoctorWorkingHours copyWith({
    String? doctorId,
    int? dayOfWeek,
    bool? isEnabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return DoctorWorkingHours(
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

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

  factory DoctorWorkingHours.fromJson(Map<String, dynamic> json) {
    return DoctorWorkingHours(
      doctorId: (json['doctor_id'] ?? '').toString(),
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
      isEnabled: (json['is_enabled'] as bool?) ?? false,
      startTime: _parseTime(json['start_time']?.toString()),
      endTime: _parseTime(json['end_time']?.toString()),
    );
  }

  Map<String, dynamic> toUpsertJson() => {
    'doctor_id': doctorId,
    'day_of_week': dayOfWeek,
    'is_enabled': isEnabled,
    'start_time': _formatTime(startTime),
    'end_time': _formatTime(endTime),
    'updated_at': DateTime.now().toIso8601String(),
  };
}
