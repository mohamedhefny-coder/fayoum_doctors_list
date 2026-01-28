package com.fayoum.doctors_list

import com.fayoum.doctors_list.alarm.AlarmScheduler
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "alarm_tts")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"scheduleDaily" -> {
						val requestCode = call.argument<Int>("requestCode") ?: 0
						val medicineName = call.argument<String>("medicineName") ?: ""
						val hour = call.argument<Int>("hour") ?: 0
						val minute = call.argument<Int>("minute") ?: 0

						AlarmScheduler.cancel(this, requestCode)
						AlarmScheduler.scheduleDaily(this, requestCode, medicineName, hour, minute)
						result.success(null)
					}

					"scheduleEveryNMonths" -> {
						val requestCode = call.argument<Int>("requestCode") ?: 0
						val medicineName = call.argument<String>("medicineName") ?: ""
						val startMillis = call.argument<Number>("startMillis")?.toLong() ?: 0L
						val intervalMonths = call.argument<Int>("intervalMonths") ?: 3

						AlarmScheduler.cancel(this, requestCode)
						AlarmScheduler.scheduleEveryNMonths(
							this,
							requestCode,
							medicineName,
							startMillis,
							intervalMonths,
						)
						result.success(null)
					}

					"cancel" -> {
						val requestCode = call.argument<Int>("requestCode") ?: 0
						AlarmScheduler.cancel(this, requestCode)
						result.success(null)
					}

					else -> result.notImplemented()
				}
			}
	}
}
