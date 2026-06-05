package com.recettealarm.app;

import android.app.*;
import android.content.*;
import android.database.*;
import android.graphics.Typeface;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.util.*;

public class CookingActivity extends Activity {
    DB db;
    ArrayList<long[]> ids = new ArrayList<>();
    ArrayList<String[]> txt = new ArrayList<>();
    int idx = 0;
    TextView timer, desc, note, stepTitle;
    CountDownTimer cd;
    long rid;
    boolean running = false;
    long remainingMs = 0;

    public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        db = new DB(this);
        rid = getIntent().getLongExtra("id", 0);

        Cursor c = db.steps(rid);
        while (c.moveToNext()) {
            ids.add(new long[]{c.getLong(0), c.getInt(4)});
            txt.add(new String[]{c.getString(3), c.getString(6)});
        }
        c.close();
        draw();
    }

    void draw() {
        LinearLayout r = UI.root(this);
        Button back = UI.whiteBtn(this, "← Retour recette");
        r.addView(back);
        back.setOnClickListener(v -> finish());

        r.addView(UI.center(this, "Mode Cuisine Anti-Brûlure", 24, Typeface.BOLD));
        stepTitle = UI.center(this, "", 16, Typeface.NORMAL);
        r.addView(stepTitle);

        LinearLayout timerBox = UI.section(this);
        timer = UI.center(this, "00:00", 62, Typeface.BOLD);
        timerBox.addView(UI.center(this, "TEMPS RESTANT", 14, Typeface.BOLD));
        timerBox.addView(timer);
        timerBox.addView(UI.center(this, "🔔 Alarme activée pour cette étape", 14, Typeface.NORMAL));
        r.addView(timerBox);

        desc = UI.tv(this, "", 25, Typeface.BOLD);
        note = UI.tv(this, "", 18, Typeface.NORMAL);
        note.setTextColor(UI.danger);
        r.addView(desc);
        r.addView(note);

        Button start = UI.btn(this, "▶ Démarrer / Relancer");
        Button pause = UI.whiteBtn(this, "⏸ Pause");
        Button plus = UI.whiteBtn(this, "+5 minutes");
        Button next = UI.btn(this, "✓ Étape Suivante");
        r.addView(start);
        r.addView(pause);
        r.addView(plus);
        r.addView(next);
        r.addView(UI.center(this, "🔒 Mode Anti-Brûlure : l'écran reste allumé", 13, Typeface.NORMAL));

        start.setOnClickListener(v -> startStep(getCurrentMinutes()));
        pause.setOnClickListener(v -> pauseTimer());
        plus.setOnClickListener(v -> startStep(5));
        next.setOnClickListener(v -> nextStep());

        showStep();
    }

    int getCurrentMinutes() {
        if (ids.size() == 0) return 0;
        return (int) ids.get(idx)[1];
    }

    void showStep() {
        if (ids.size() == 0) {
            stepTitle.setText("Aucune étape");
            desc.setText("Ajoute d'abord des étapes dans Admin.");
            note.setText("");
            timer.setText("00:00");
            return;
        }
        stepTitle.setText("Étape " + (idx + 1) + " sur " + ids.size());
        desc.setText(txt.get(idx)[0]);
        note.setText("⚠ Note : " + safe(txt.get(idx)[1]));
        timer.setText(String.format(Locale.FRANCE, "%02d:00", getCurrentMinutes()));
        remainingMs = getCurrentMinutes() * 60_000L;
    }

    String safe(String s) {
        return s == null || s.trim().isEmpty() ? "Vérifier la cuisson et remuer le plat." : s;
    }

    void startStep(int minutes) {
        if (ids.size() == 0 || minutes <= 0) return;
        if (cd != null) cd.cancel();
        long ms = minutes * 60_000L;
        remainingMs = ms;
        running = true;

        AlarmReceiver.schedule(this, ms, safe(txt.get(idx)[1]), "Étape " + (idx + 1));

        cd = new CountDownTimer(ms, 1000) {
            public void onTick(long m) {
                remainingMs = m;
                timer.setText(String.format(Locale.FRANCE, "%02d:%02d", m / 60000, (m / 1000) % 60));
            }

            public void onFinish() {
                running = false;
                timer.setText("00:00");
                // Ne lance pas une deuxième alarme ici : AlarmReceiver déclenche l'écran plein écran.
            }
        }.start();
    }

    void pauseTimer() {
        if (cd != null) cd.cancel();
        running = false;
        UI.toast(this, "Timer en pause");
    }

    void nextStep() {
        if (cd != null) cd.cancel();
        running = false;
        idx++;
        if (idx >= ids.size()) {
            UI.toast(this, "Recette terminée ✅");
            finish();
        } else {
            showStep();
        }
    }

    protected void onDestroy() {
        super.onDestroy();
        if (cd != null) cd.cancel();
    }
}
