package com.fayoum.doctors_list.alarm

import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

object TimeMath {

    fun nextDailyTriggerMillis(hour: Int, minute: Int): Long {
        val now = ZonedDateTime.now(ZoneId.systemDefault())
        var next = now.withHour(hour).withMinute(minute).withSecond(0).withNano(0)
        if (!next.isAfter(now)) {
            next = next.plusDays(1)
        }
        return next.toInstant().toEpochMilli()
    }

    fun nextEveryNMonthsTriggerMillis(startMillis: Long, intervalMonths: Int): Long {
        val zone = ZoneId.systemDefault()
        var next = Instant.ofEpochMilli(startMillis).atZone(zone)
        val now = ZonedDateTime.now(zone)

        while (!next.isAfter(now)) {
            next = next.plusMonths(intervalMonths.toLong())
        }

        return next.toInstant().toEpochMilli()
    }

    fun addMonthsClamped(baseMillis: Long, monthsToAdd: Int): Long {
        val zone = ZoneId.systemDefault()
        val base = Instant.ofEpochMilli(baseMillis).atZone(zone).toLocalDateTime()

        val target = base.plusMonths(monthsToAdd.toLong())
        val clampedDay = minOf(target.dayOfMonth, target.toLocalDate().lengthOfMonth())
        val clamped = LocalDateTime.of(
            target.year,
            target.month,
            clampedDay,
            target.hour,
            target.minute,
            0,
            0,
        )

        return clamped.atZone(zone).toInstant().toEpochMilli()
    }
}
