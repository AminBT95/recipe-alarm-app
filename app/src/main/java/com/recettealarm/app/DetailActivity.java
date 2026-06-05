package com.recettealarm.app;

import android.app.*;
import android.content.*;
import android.database.*;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.*;
import android.widget.*;

public class DetailActivity extends Activity {
    long id;
    DB db;
    String video = "";

    public void onCreate(Bundle b) {
        super.onCreate(b);
        db = new DB(this);
        id = getIntent().getLongExtra("id", 0);
        draw();
    }

    void draw() {
        LinearLayout r = UI.root(this);
        Button back = UI.whiteBtn(this, "← Retour");
        r.addView(back);
        back.setOnClickListener(v -> finish());

        Cursor c = db.one(id);
        String title = "Recette";
        if (c.moveToFirst()) {
            title = c.getString(c.getColumnIndexOrThrow("title"));
            video = c.getString(c.getColumnIndexOrThrow("video"));
            r.addView(UI.tv(this, title, 30, Typeface.BOLD));
            r.addView(UI.tv(this,
                    c.getString(c.getColumnIndexOrThrow("category")) + "   •   ⏱ " + c.getInt(c.getColumnIndexOrThrow("time")) + " min   •   👥 " + c.getInt(c.getColumnIndexOrThrow("servings")) + " pers.",
                    16, Typeface.NORMAL));
        }
        c.close();

        Button cook = UI.btn(this, "▶ Démarrer la Cuisine");
        r.addView(cook);
        cook.setOnClickListener(v -> startActivity(new Intent(this, CookingActivity.class).putExtra("id", id)));

        if (video != null && video.trim().length() > 0) {
            Button openVideo = UI.whiteBtn(this, "🎥 Ouvrir la vidéo");
            r.addView(openVideo);
            openVideo.setOnClickListener(v -> startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(video))));
        }

        Button edit = UI.whiteBtn(this, "⚙ Admin : Modifier / Ajouter");
        r.addView(edit);
        edit.setOnClickListener(v -> startActivity(new Intent(this, EditRecipeActivity.class).putExtra("id", id)));

        r.addView(UI.tv(this, "Ingrédients", 24, Typeface.BOLD));
        LinearLayout ingBox = UI.section(this);
        Cursor i = db.ingredients(id);
        int count = 0;
        while (i.moveToNext()) {
            count++;
            ingBox.addView(UI.smallCard(this, "• " + i.getString(2) + "     " + i.getString(3) + " " + i.getString(4)));
        }
        i.close();
        if (count == 0) ingBox.addView(UI.smallCard(this, "Aucun ingrédient encore."));
        r.addView(ingBox);

        r.addView(UI.tv(this, "Étapes anti-brûlure", 24, Typeface.BOLD));
        Cursor s = db.steps(id);
        int stepCount = 0;
        while (s.moveToNext()) {
            stepCount++;
            r.addView(UI.card(this, "Étape " + s.getInt(2) + "   •   ⏱ " + s.getInt(4) + " min\n" + s.getString(3) + "\n⚠ " + s.getString(6)));
        }
        s.close();
        if (stepCount == 0) r.addView(UI.smallCard(this, "Ajoute au moins une étape avant de lancer la cuisine."));
    }
}
