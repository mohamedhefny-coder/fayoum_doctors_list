package com.fayoum.doctors_list.alarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object AlarmUi {

    fun showAlarm(context: Context, notificationId: Int, medicineName: String) {
        createChannel(context)

        val activityIntent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(AlarmConstants.EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(AlarmConstants.EXTRA_MEDICINE_NAME, medicineName)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )

        val notification = NotificationCompat.Builder(context, AlarmConstants.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("منبه")
            .setContentText("موعد تناول $medicineName")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(true)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .build()

        NotificationManagerCompat.from(context).notify(notificationId, notification)

        // Also start the activity immediately (some devices restrict full-screen intents)
        context.startActivity(activityIntent)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val existing = manager.getNotificationChannel(AlarmConstants.NOTIFICATION_CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            AlarmConstants.NOTIFICATION_CHANNEL_ID,
            AlarmConstants.NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "تنبيه قوي لتذكير بتناول الدواء"
            setSound(null, null)
            enableVibration(true)
            enableLights(true)
        }

        manager.createNotificationChannel(channel)
    }

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}
