package com.fayoum.doctors_list.alarm

import android.app.Activity
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationManagerCompat
import android.speech.tts.TextToSpeech
import java.util.Locale

class AlarmActivity : Activity(), TextToSpeech.OnInitListener {

    private var ringtone: Ringtone? = null
    private var tts: TextToSpeech? = null
    private var medicineName: String = ""
    private var notificationId: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
        )

        medicineName = intent.getStringExtra(AlarmConstants.EXTRA_MEDICINE_NAME) ?: ""
        notificationId = intent.getIntExtra(AlarmConstants.EXTRA_NOTIFICATION_ID, 0)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 64, 48, 64)
            gravity = Gravity.CENTER
        }

        val title = TextView(this).apply {
            text = "موعد تناول الدواء"
            textSize = 24f
            setTextColor(0xFF111827.toInt())
            gravity = Gravity.CENTER
        }

        val body = TextView(this).apply {
            text = if (medicineName.isBlank()) {
                "حان موعد تناول الدواء"
            } else {
                "موعد تناول: $medicineName"
            }
            textSize = 20f
            setTextColor(0xFF0F172A.toInt())
            gravity = Gravity.CENTER
        }

        val stop = Button(this).apply {
            text = "إيقاف"
            textSize = 18f
            setOnClickListener { stopAndFinish() }
        }

        root.addView(title)
        root.addView(body)
        root.addView(stop)
        setContentView(root)

        startRingtone()
        tts = TextToSpeech(this, this)
    }

    private fun startRingtone() {
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        ringtone = RingtoneManager.getRingtone(this, uri)?.apply {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }
            isLooping = true
            play()
        }
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) return

        tts?.language = Locale("ar")
        val spoken = if (medicineName.isBlank()) {
            "موعد تناول الدواء"
        } else {
            "موعد تناول $medicineName"
        }
        tts?.speak(spoken, TextToSpeech.QUEUE_FLUSH, null, "medication_alarm")
    }

    private fun stopAndFinish() {
        ringtone?.stop()
        ringtone = null

        tts?.stop()
        tts?.shutdown()
        tts = null

        NotificationManagerCompat.from(this).cancel(notificationId)

        finish()
    }

    override fun onDestroy() {
        ringtone?.stop()
        tts?.shutdown()
        super.onDestroy()
    }

    override fun onBackPressed() {
        stopAndFinish()
    }
}
