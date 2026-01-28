import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/alarm_tts_service.dart';
import '../services/notification_service.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() =>
      _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  static const _storageKey = 'medication_reminders_v1';
  static const _nextIdKey = 'medication_reminders_next_id_v1';
  static const _intervalOccurrenceCount = 12;

  final List<_MedicationReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => _MedicationReminder.fromJson(e as Map<String, dynamic>))
            .toList();
        _reminders
          ..clear()
          ..addAll(list);
      } catch (_) {
        // ignore corrupted data
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_reminders.map((e) => e.toJson()).toList()),
    );
  }

  Future<int> _nextReminderId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, current + 1);
    return current;
  }

  Future<void> _addReminder() async {
    final result = await showDialog<_MedicationReminderDraft>(
      context: context,
      builder: (_) => const _MedicationReminderDialog(title: 'إضافة تذكير دواء'),
    );

    if (result == null) return;

    final reminderId = await _nextReminderId();

    final reminder = _MedicationReminder.fromDraft(
      id: reminderId,
      draft: result,
    );

    await _scheduleForReminder(reminder);

    setState(() => _reminders.add(reminder));
    await _save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة التذكير بنجاح')),
    );
  }

  Future<void> _deleteReminder(_MedicationReminder reminder) async {
    await NotificationService.cancelMany(reminder.allNotificationIds);
    await AlarmTtsService.cancelMany(reminder.alarmRequestCodes);
    setState(() => _reminders.removeWhere((r) => r.id == reminder.id));
    await _save();
  }

  Future<void> _scheduleForReminder(_MedicationReminder reminder) async {
    if (reminder.recurrence == _RecurrenceType.daily) {
      for (var i = 0; i < reminder.dailyTimes.length; i++) {
        final time = reminder.dailyTimes[i];
        final notificationId = reminder.notificationIdForDailyIndex(i);
        await NotificationService.scheduleDailyMedicationReminder(
          notificationId: notificationId,
          medicineName: reminder.name,
          time: time,
        );

        // Strong alarm + spoken phrase (Android only)
        await AlarmTtsService.scheduleDailyAlarm(
          requestCode: notificationId,
          medicineName: reminder.name,
          time: time,
        );
      }
      return;
    }

    // Every N months: schedule a number of future occurrences.
    if (reminder.startDateTime == null || reminder.intervalMonths == null) return;

    var base = reminder.startDateTime!;
    final now = DateTime.now();
    while (base.isBefore(now)) {
      base = _addMonths(base, reminder.intervalMonths!);
    }

    for (var i = 0; i < _intervalOccurrenceCount; i++) {
      final dt = _addMonths(base, reminder.intervalMonths! * i);
      final notificationId = reminder.notificationIdForIntervalIndex(i);
      await NotificationService.scheduleMedicationAtDateTime(
        notificationId: notificationId,
        medicineName: reminder.name,
        dateTime: dt,
      );
    }

    // Strong alarm chain (Android only): schedule next occurrence only; receiver will reschedule.
    await AlarmTtsService.scheduleEveryNMonthsAlarm(
      requestCode: reminder.alarmRequestCodeForEveryNMonths,
      medicineName: reminder.name,
      startDateTime: base,
      intervalMonths: reminder.intervalMonths!,
    );
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final year = date.year + ((date.month - 1 + monthsToAdd) ~/ 12);
    final month = ((date.month - 1 + monthsToAdd) % 12) + 1;
    final day = date.day;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final clampedDay = day > lastDayOfTargetMonth ? lastDayOfTargetMonth : day;
    return DateTime(
      year,
      month,
      clampedDay,
      date.hour,
      date.minute,
    );
  }

  Future<void> _editReminder(_MedicationReminder reminder) async {
    final result = await showDialog<_MedicationReminderDraft>(
      context: context,
      builder: (_) => _MedicationReminderDialog(
        title: 'تعديل التذكير',
        initialName: reminder.name,
        initialRecurrence: reminder.recurrence,
        initialDailyTimes: reminder.dailyTimes,
        initialStartDateTime: reminder.startDateTime,
        initialIntervalMonths: reminder.intervalMonths,
      ),
    );

    if (result == null) return;

    final updated = _MedicationReminder.fromDraft(id: reminder.id, draft: result);

    await NotificationService.cancelMany(reminder.allNotificationIds);
    await AlarmTtsService.cancelMany(reminder.alarmRequestCodes);
    await _scheduleForReminder(updated);

    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      setState(() => _reminders[index] = updated);
      await _save();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعديل التذكير بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تذكير الأدوية'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addReminder,
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة دواء'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? _EmptyState(onAdd: _addReminder)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return Dismissible(
                        key: ValueKey(reminder.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('حذف التذكير؟'),
                                  content: Text(
                                    'سيتم إيقاف جميع تنبيهات "${reminder.name}".',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('إلغاء'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _deleteReminder(reminder),
                        child: _ReminderCard(
                          reminder: reminder,
                          onEdit: () => _editReminder(reminder),
                          onDelete: () => _deleteReminder(reminder),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemCount: _reminders.length,
                  ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm,
                size: 44,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد تذكيرات بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف اسم الدواء ومواعيد الجرعات ليصلك تنبيه بصوت في الوقت المحدد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('إضافة تذكير'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  final _MedicationReminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.85),
                        AppColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reminder.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reminder.recurrence == _RecurrenceType.daily)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reminder.dailyTimes
                    .map(
                      (t) => Chip(
                        label: Text(_formatTime(context, t)),
                        avatar: const Icon(Icons.schedule, size: 18),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                      ),
                    )
                    .toList(),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.event_repeat, size: 18),
                    label: Text('كل ${reminder.intervalMonths ?? 0} شهور'),
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.10),
                  ),
                  if (reminder.startDateTime != null)
                    Chip(
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text(_formatDateTime(context, reminder.startDateTime!)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              'اضغط للتعديل',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
      alwaysUse24HourFormat: false,
    );
    return '$date - $time';
  }
}

class _MedicationReminderDialog extends StatefulWidget {
  const _MedicationReminderDialog({
    required this.title,
    this.initialName,
    this.initialRecurrence,
    this.initialDailyTimes,
    this.initialStartDateTime,
    this.initialIntervalMonths,
  });

  final String title;
  final String? initialName;
  final _RecurrenceType? initialRecurrence;
  final List<TimeOfDay>? initialDailyTimes;
  final DateTime? initialStartDateTime;
  final int? initialIntervalMonths;

  @override
  State<_MedicationReminderDialog> createState() => _MedicationReminderDialogState();
}

class _MedicationReminderDialogState extends State<_MedicationReminderDialog> {
  late final TextEditingController _nameController;
  final List<TimeOfDay> _times = [];

  late _RecurrenceType _recurrence;
  late DateTime _startDate;
  late TimeOfDay _singleTime;
  late int _intervalMonths;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _recurrence = widget.initialRecurrence ?? _RecurrenceType.daily;

    if (widget.initialDailyTimes != null) {
      _times.addAll(widget.initialDailyTimes!);
      _times.sort((a, b) =>
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    }

    final start = widget.initialStartDateTime ?? DateTime.now();
    _startDate = DateTime(start.year, start.month, start.day);
    _singleTime = TimeOfDay(hour: start.hour, minute: start.minute);
    _intervalMonths = widget.initialIntervalMonths ?? 3;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    final exists = _times.any((t) => t.hour == picked.hour && t.minute == picked.minute);
    if (!exists) {
      setState(() {
        _times.add(picked);
        _times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _removeTime(TimeOfDay time) {
    setState(() {
      _times.removeWhere((t) => t.hour == time.hour && t.minute == time.minute);
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل اسم الدواء')),
      );
      return;
    }

    if (_recurrence == _RecurrenceType.daily) {
      if (_times.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('من فضلك أضف موعد جرعة واحد على الأقل')),
        );
        return;
      }

      Navigator.pop(
        context,
        _MedicationReminderDraft.daily(name: name, times: List.of(_times)),
      );
      return;
    }

    if (_intervalMonths < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فترة التكرار يجب أن تكون شهر واحد على الأقل')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _singleTime.hour,
      _singleTime.minute,
    );

    Navigator.pop(
      context,
      _MedicationReminderDraft.everyNMonths(
        name: name,
        startDateTime: startDateTime,
        intervalMonths: _intervalMonths,
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickSingleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _singleTime,
    );

    if (picked == null) return;
    setState(() => _singleTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الدواء',
                hintText: 'مثال: Augmentin',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_RecurrenceType>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'نوع التذكير'),
              items: const [
                DropdownMenuItem(
                  value: _RecurrenceType.daily,
                  child: Text('يومي (مواعيد جرعات يومية)'),
                ),
                DropdownMenuItem(
                  value: _RecurrenceType.everyNMonths,
                  child: Text('كل عدة شهور (مثلاً كل 3 شهور)'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _recurrence = v);
              },
            ),
            const SizedBox(height: 12),

            if (_recurrence == _RecurrenceType.daily) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'مواعيد الجرعات',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_times.isEmpty)
              Text(
                'لم يتم إضافة مواعيد بعد',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times
                    .map(
                      (t) => Chip(
                        label: Text(MaterialLocalizations.of(context)
                            .formatTimeOfDay(t, alwaysUse24HourFormat: false)),
                        onDeleted: () => _removeTime(t),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.add_alarm),
              label: const Text('إضافة وقت'),
            ),
            ] else ...[
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'موعد أول جرعة',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.event),
                      label: Text(localizations.formatShortDate(_startDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickSingleTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(localizations.formatTimeOfDay(
                        _singleTime,
                        alwaysUse24HourFormat: false,
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'يتكرر كل $_intervalMonths شهور',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_intervalMonths > 1) _intervalMonths -= 1;
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _intervalMonths += 1);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Text(
                'ملاحظة: سيتم جدولة عدة تذكيرات مستقبلية تلقائياً.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

enum _RecurrenceType { daily, everyNMonths }

class _MedicationReminderDraft {
  const _MedicationReminderDraft._({
    required this.name,
    required this.recurrence,
    this.dailyTimes,
    this.startDateTime,
    this.intervalMonths,
  });

  factory _MedicationReminderDraft.daily({
    required String name,
    required List<TimeOfDay> times,
  }) {
    return _MedicationReminderDraft._(
      name: name,
      recurrence: _RecurrenceType.daily,
      dailyTimes: times,
    );
  }

  factory _MedicationReminderDraft.everyNMonths({
    required String name,
    required DateTime startDateTime,
    required int intervalMonths,
  }) {
    return _MedicationReminderDraft._(
      name: name,
      recurrence: _RecurrenceType.everyNMonths,
      startDateTime: startDateTime,
      intervalMonths: intervalMonths,
    );
  }

  final String name;
  final _RecurrenceType recurrence;
  final List<TimeOfDay>? dailyTimes;
  final DateTime? startDateTime;
  final int? intervalMonths;
}

class _MedicationReminder {
  const _MedicationReminder({
    required this.id,
    required this.name,
    required this.recurrence,
    required this.dailyTimes,
    required this.startDateTime,
    required this.intervalMonths,
  });

  factory _MedicationReminder.fromDraft({
    required int id,
    required _MedicationReminderDraft draft,
  }) {
    if (draft.recurrence == _RecurrenceType.daily) {
      final times = List<TimeOfDay>.of(draft.dailyTimes ?? const []);
      times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      return _MedicationReminder(
        id: id,
        name: draft.name,
        recurrence: _RecurrenceType.daily,
        dailyTimes: times,
        startDateTime: null,
        intervalMonths: null,
      );
    }

    return _MedicationReminder(
      id: id,
      name: draft.name,
      recurrence: _RecurrenceType.everyNMonths,
      dailyTimes: const [],
      startDateTime: draft.startDateTime,
      intervalMonths: draft.intervalMonths,
    );
  }

  final int id;
  final String name;
  final _RecurrenceType recurrence;
  final List<TimeOfDay> dailyTimes;
  final DateTime? startDateTime;
  final int? intervalMonths;

  int notificationIdForDailyIndex(int index) => id * 100 + index;
  int notificationIdForIntervalIndex(int index) => id * 1000 + index;

  // For Android strong-alarm chain (every N months) we keep one request code.
  int get alarmRequestCodeForEveryNMonths => id * 1000;

  Iterable<int> get alarmRequestCodes {
    if (recurrence == _RecurrenceType.daily) {
      return List<int>.generate(
        dailyTimes.length,
        (i) => notificationIdForDailyIndex(i),
      );
    }
    return [alarmRequestCodeForEveryNMonths];
  }

  Iterable<int> get allNotificationIds {
    if (recurrence == _RecurrenceType.daily) {
      return List<int>.generate(
        dailyTimes.length,
        (i) => notificationIdForDailyIndex(i),
      );
    }

    return List<int>.generate(
      _MedicationRemindersScreenState._intervalOccurrenceCount,
      (i) => notificationIdForIntervalIndex(i),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'recurrence': recurrence == _RecurrenceType.daily ? 'daily' : 'every_n_months',
        'times': dailyTimes
            .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
            .toList(),
        'startDateTime': startDateTime?.toIso8601String(),
        'intervalMonths': intervalMonths,
      };

  static _MedicationReminder fromJson(Map<String, dynamic> json) {
    final recurrenceRaw = json['recurrence']?.toString();
    final recurrence = recurrenceRaw == 'every_n_months'
        ? _RecurrenceType.everyNMonths
        : _RecurrenceType.daily;

    final timesRaw = (json['times'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    final parsedTimes = <TimeOfDay>[];
    for (final value in timesRaw) {
      final parts = value.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;
      parsedTimes.add(TimeOfDay(hour: h, minute: m));
    }
    parsedTimes.sort((a, b) =>
        (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    DateTime? start;
    final startRaw = json['startDateTime']?.toString();
    if (startRaw != null && startRaw.isNotEmpty) {
      start = DateTime.tryParse(startRaw);
    }

    final intervalMonths = (json['intervalMonths'] as num?)?.toInt();

    return _MedicationReminder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      recurrence: recurrence,
      dailyTimes: recurrence == _RecurrenceType.daily ? parsedTimes : const [],
      startDateTime: recurrence == _RecurrenceType.everyNMonths ? start : null,
      intervalMonths: recurrence == _RecurrenceType.everyNMonths ? intervalMonths : null,
    );
  }
}
