package com.recettealarm.app;

import android.app.*;
import android.content.*;
import android.media.*;
import android.os.*;
import android.provider.Settings;
import android.graphics.Typeface;
import android.view.*;
import android.widget.*;

public class AlarmActivity extends Activity {
    MediaPlayer mp;
    Vibrator vib;
    Handler handler = new Handler();
    TextView warn;

    public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON |
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON |
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        );

        LinearLayout r = UI.root(this);
        r.addView(UI.center(this, "🔔", 62, Typeface.BOLD));
        r.addView(UI.center(this, "TEMPS ÉCOULÉ !", 34, Typeface.BOLD));
        r.addView(UI.center(this, getIntent().getStringExtra("title"), 18, Typeface.BOLD));

        LinearLayout box = UI.section(this);
        box.setBackground(UI.stroke(0xffffffff, UI.dp(this, 28), UI.danger));
        box.addView(UI.center(this, "NOTE IMPORTANTE", 15, Typeface.BOLD));
        box.addView(UI.center(this, safe(getIntent().getStringExtra("note")), 24, Typeface.BOLD));
        box.addView(UI.center(this, "00:00", 34, Typeface.BOLD));
        r.addView(box);

        Button stop = UI.btn(this, "■ ARRÊTER");
        Button plus = UI.whiteBtn(this, "+5 MIN");
        Button ok = UI.whiteBtn(this, "✅ J'ai vérifié le plat");
        r.addView(stop);
        r.addView(plus);
        r.addView(ok);

        warn = UI.center(this, "⚠ Si l'alarme continue, le plat risque de brûler.", 13, Typeface.NORMAL);
        r.addView(warn);

        startNoise();
        handler.postDelayed(() -> warn.setText("⚠ Attention : vérifie immédiatement la cuisson."), 30000);
        handler.postDelayed(() -> restartNoise(), 60000);

        stop.setOnClickListener(v -> finish());
        ok.setOnClickListener(v -> finish());
        plus.setOnClickListener(v -> {
            AlarmReceiver.schedule(this, 5 * 60_000L, "Rappel +5 minutes : vérifie le plat", "Rappel cuisson");
            finish();
        });
    }

    String safe(String s) {
        return s == null || s.trim().isEmpty()
                ? "Vérifier la cuisson et remuer le plat immédiatement pour éviter qu'il ne brûle."
                : s;
    }

    void startNoise() {
        try {
            mp = MediaPlayer.create(this, Settings.System.DEFAULT_ALARM_ALERT_URI);
            if (mp != null) {
                mp.setLooping(true);
                mp.start();
            }
        } catch (Exception ignored) {}
        vib = (Vibrator) getSystemService(VIBRATOR_SERVICE);
        if (vib != null) {
            if (Build.VERSION.SDK_INT >= 26) vib.vibrate(VibrationEffect.createWaveform(new long[]{0, 900, 300, 900, 300, 1300}, 0));
            else vib.vibrate(new long[]{0, 900, 300, 900, 300, 1300}, 0);
        }
    }

    void restartNoise() {
        if (mp == null || !mp.isPlaying()) startNoise();
    }

    public void onDestroy() {
        super.onDestroy();
        handler.removeCallbacksAndMessages(null);
        if (mp != null) {
            try { mp.stop(); } catch (Exception ignored) {}
            mp.release();
        }
        if (vib != null) vib.cancel();
        ((NotificationManager) getSystemService(NOTIFICATION_SERVICE)).cancel(88);
    }
}
