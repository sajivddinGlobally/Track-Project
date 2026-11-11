package com.example.track_loved

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels(this)
    }

    companion object {
        fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return

                val packageName = context.packageName
                val sirenUri = Uri.parse("${ContentResolver.SCHEME_ANDROID_RESOURCE}://${packageName}/raw/siren")
                val chimeUri = Uri.parse("${ContentResolver.SCHEME_ANDROID_RESOURCE}://${packageName}/raw/chime")

                val alarmAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()

                val notifAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()

                // Emergency SOS Channels (covers emergency_channel, v2, v3)
                val emergencyChannels = listOf("emergency_channel", "emergency_channel_v2", "emergency_channel_v3")
                for (id in emergencyChannels) {
                    val channel = NotificationChannel(
                        id,
                        "Emergency & SOS Alerts",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "High priority siren alerts for emergency and SOS broadcasts"
                        setSound(sirenUri, alarmAttributes)
                        enableLights(true)
                        enableVibration(true)
                        vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                    }
                    notificationManager.createNotificationChannel(channel)
                }

                // General Notification Channels (covers default_channel, v2, v3)
                val defaultChannels = listOf("default_channel", "default_channel_v2", "default_channel_v3")
                for (id in defaultChannels) {
                    val channel = NotificationChannel(
                        id,
                        "General Notifications",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Notifications for chats, reminders, and requests"
                        setSound(chimeUri, notifAttributes)
                        enableLights(true)
                        enableVibration(true)
                    }
                    notificationManager.createNotificationChannel(channel)
                }

                // Location Tracking Foreground Service Channel (Silent & Low Importance)
                val locationChannel = NotificationChannel(
                    "geolocator_channel",
                    "Location Service",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Ongoing location tracking notification"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                }
                notificationManager.createNotificationChannel(locationChannel)
            }
        }
    }
}

