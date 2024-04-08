package io.atomic.atomic_sdk_flutter.utils

import android.content.res.Configuration
import android.os.Build
import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

fun tryParseDate(configuration : Configuration, dateString : String) : Date? {
    val locale : Locale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        configuration.locales.get(0)
    } else{
        @Suppress("DEPRECATION")
        configuration.locale
    }
    return try {
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", locale).parse(dateString)
    } catch (e : ParseException) {
        null
    }
}