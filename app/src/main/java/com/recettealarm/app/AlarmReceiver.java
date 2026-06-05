package com.recettealarm.app;

import android.app.*;
import android.content.*;
import android.media.AudioAttributes;
import android.net.Uri;
import android.os.*;
import android.provider.Settings;

public class AlarmReceiver extends BroadcastReceiver {
    static String CH = "recette_alarm";

    public void onReceive(Context c, Intent i) {
        create(c);
        String note = i.getStringExtra("note");
        String title = i.getStringExtra("title");
        if (note == null || note.trim().isEmpty()) note = "Vérifie la cuisson et remue le plat immédiatement.";
        if (title == null) title = "Temps écoulé !";

        Intent full = new Intent(c, AlarmActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP)
                .putExtra("note", note)
                .putExtra("title", title);

        PendingIntent pi = PendingIntent.getActivity(c, 200, full,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        Notification.Builder nb = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(c, CH)
                : new Notification.Builder(c);

        Notification n = nb
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("Recette Alarm - Anti-Brûlure")
                .setContentText(note)
                .setPriority(Notification.PRIORITY_MAX)
                .setCategory(Notification.CATEGORY_ALARM)
                .setFullScreenIntent(pi, true)
                .setContentIntent(pi)
                .setOngoing(true)
                .setAutoCancel(false)
                .build();

        ((NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE)).notify(88, n);

        try { c.startActivity(full); } catch (Exception ignored) {}
    }

    static void schedule(Context c, long ms, String note, String title) {
        Intent i = new Intent(c, AlarmReceiver.class).putExtra("note", note).putExtra("title", title);
        PendingIntent pi = PendingIntent.getBroadcast(c, 88, i,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        long at = System.currentTimeMillis() + ms;
        if (Build.VERSION.SDK_INT >= 31 && !am.canScheduleExactAlarms()) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi);
        } else {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi);
        }
    }

    static void create(Context c) {
        if (Build.VERSION.SDK_INT >= 26) {
            Uri sound = Settings.System.DEFAULT_ALARM_ALERT_URI;
            AudioAttributes attrs = new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build();
            NotificationChannel ch = new NotificationChannel(CH, "Alarmes cuisson", NotificationManager.IMPORTANCE_HIGH);
            ch.setDescription("Alarmes fortes pour éviter les plats brûlés");
            ch.setSound(sound, attrs);
            ch.enableVibration(true);
            ch.setVibrationPattern(new long[]{0, 800, 300, 800, 300, 1200});
            ch.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
            ((NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE)).createNotificationChannel(ch);
        }
    }
}
