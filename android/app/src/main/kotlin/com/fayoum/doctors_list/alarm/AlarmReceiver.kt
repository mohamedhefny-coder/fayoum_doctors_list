package com.fayoum.doctors_list.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val kind = intent.getStringExtra(AlarmConstants.EXTRA_KIND) ?: return
        val medicineName = intent.getStringExtra(AlarmConstants.EXTRA_MEDICINE_NAME) ?: ""
        val hour = intent.getIntExtra(AlarmConstants.EXTRA_HOUR, -1).takeIf { it >= 0 }
        val minute = intent.getIntExtra(AlarmConstants.EXTRA_MINUTE, -1).takeIf { it >= 0 }
        val intervalMonths = intent.getIntExtra(AlarmConstants.EXTRA_INTERVAL_MONTHS, -1).takeIf { it > 0 }
        val requestCode = intent.getIntExtra("requestCode", 0)

        // Show full-screen alarm + speak.
        AlarmUi.showAlarm(context, requestCode, medicineName)

        // Reschedule next occurrence (chain)
        AlarmScheduler.rescheduleNextFromFire(
            context = context,
            requestCode = requestCode,
            kind = kind,
            medicineName = medicineName,
            hour = hour,
            minute = minute,
            intervalMonths = intervalMonths,
            firedAtMillis = System.currentTimeMillis(),
        )
    }
}
