package com.fayoum.doctors_list.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object AlarmScheduler {

    fun scheduleDaily(
        context: Context,
        requestCode: Int,
        medicineName: String,
        hour: Int,
        minute: Int,
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("requestCode", requestCode)
            putExtra(AlarmConstants.EXTRA_KIND, AlarmConstants.KIND_DAILY)
            putExtra(AlarmConstants.EXTRA_MEDICINE_NAME, medicineName)
            putExtra(AlarmConstants.EXTRA_HOUR, hour)
            putExtra(AlarmConstants.EXTRA_MINUTE, minute)
        }

        val triggerAtMillis = TimeMath.nextDailyTriggerMillis(hour, minute)
        scheduleExact(context, requestCode, intent, triggerAtMillis)
    }

    fun scheduleEveryNMonths(
        context: Context,
        requestCode: Int,
        medicineName: String,
        startMillis: Long,
        intervalMonths: Int,
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("requestCode", requestCode)
            putExtra(AlarmConstants.EXTRA_KIND, AlarmConstants.KIND_EVERY_N_MONTHS)
            putExtra(AlarmConstants.EXTRA_MEDICINE_NAME, medicineName)
            putExtra(AlarmConstants.EXTRA_INTERVAL_MONTHS, intervalMonths)
        }

        val triggerAtMillis = TimeMath.nextEveryNMonthsTriggerMillis(startMillis, intervalMonths)
        scheduleExact(context, requestCode, intent, triggerAtMillis)
    }

    fun rescheduleNextFromFire(
        context: Context,
        requestCode: Int,
        kind: String,
        medicineName: String,
        hour: Int?,
        minute: Int?,
        intervalMonths: Int?,
        firedAtMillis: Long,
    ) {
        when (kind) {
            AlarmConstants.KIND_DAILY -> {
                if (hour == null || minute == null) return
                scheduleDaily(context, requestCode, medicineName, hour, minute)
            }

            AlarmConstants.KIND_EVERY_N_MONTHS -> {
                if (intervalMonths == null) return
                val nextMillis = TimeMath.addMonthsClamped(firedAtMillis, intervalMonths)
                val intent = Intent(context, AlarmReceiver::class.java).apply {
                    putExtra("requestCode", requestCode)
                    putExtra(AlarmConstants.EXTRA_KIND, AlarmConstants.KIND_EVERY_N_MONTHS)
                    putExtra(AlarmConstants.EXTRA_MEDICINE_NAME, medicineName)
                    putExtra(AlarmConstants.EXTRA_INTERVAL_MONTHS, intervalMonths)
                }
                scheduleExact(context, requestCode, intent, nextMillis)
            }
        }
    }

    fun cancel(context: Context, requestCode: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, AlarmReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or pendingIntentImmutableFlag(),
        )

        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun scheduleExact(
        context: Context,
        requestCode: Int,
        intent: Intent,
        triggerAtMillis: Long,
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )

        val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }

        if (canExact) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        } else {
            // Fallback to inexact if exact alarms are not allowed.
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        }
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}
