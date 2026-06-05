package com.recettealarm.app;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.database.*;
import android.os.*;
import android.graphics.Typeface;
import android.view.*;
import android.widget.*;

public class MainActivity extends Activity {
    DB db;
    LinearLayout root, list;

    public void onCreate(Bundle b) {
        super.onCreate(b);
        db = new DB(this);
        if (Build.VERSION.SDK_INT >= 33) requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 5);
        draw();
    }

    public void onResume() {
        super.onResume();
        if (list != null) load();
    }

    void draw() {
        root = UI.root(this);
        root.addView(UI.tv(this, "Bonjour Chef ! 👋", 16, Typeface.NORMAL));
        root.addView(UI.tv(this, "Recette Alarm", 34, Typeface.BOLD));
        root.addView(UI.tv(this, "Cuisine intelligente avec alarmes anti-brûlure", 15, Typeface.NORMAL));

        EditText search = UI.input(this, "🔎 Rechercher une recette...");
        root.addView(search);

        HorizontalScrollView hsv = new HorizontalScrollView(this);
        hsv.setHorizontalScrollBarEnabled(false);
        LinearLayout chips = new LinearLayout(this);
        chips.setOrientation(LinearLayout.HORIZONTAL);
        chips.addView(UI.chip(this, "▦ Tous"));
        chips.addView(UI.chip(this, "🍲 Tajines"));
        chips.addView(UI.chip(this, "🍰 Gâteaux"));
        chips.addView(UI.chip(this, "🥗 Plats"));
        chips.addView(UI.chip(this, "🥤 Jus"));
        hsv.addView(chips);
        root.addView(hsv);

        Button add = UI.btn(this, "+ Nouvelle Recette");
        root.addView(add);
        add.setOnClickListener(v -> startActivity(new Intent(this, EditRecipeActivity.class)));

        Button shop = UI.whiteBtn(this, "🛒 Liste de courses automatique");
        root.addView(shop);
        shop.setOnClickListener(v -> share(db.shoppingList()));

        root.addView(UI.tv(this, "Vos Recettes", 23, Typeface.BOLD));
        list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        root.addView(list);
        load();
    }

    void load() {
        list.removeAllViews();
        Cursor c = db.recipes();
        while (c.moveToNext()) {
            long id = c.getLong(c.getColumnIndexOrThrow("id"));
            String t = c.getString(c.getColumnIndexOrThrow("title"));
            String cat = c.getString(c.getColumnIndexOrThrow("category"));
            int time = c.getInt(c.getColumnIndexOrThrow("time"));
            int serv = c.getInt(c.getColumnIndexOrThrow("servings"));
            TextView card = UI.card(this, "🍽  " + t + "\n" + cat + "   •   ⏱ " + time + " min   •   👥 " + serv + " pers.");
            list.addView(card);
            card.setOnClickListener(v -> startActivity(new Intent(this, DetailActivity.class).putExtra("id", id)));
        }
        c.close();
    }

    void share(String s) {
        Intent i = new Intent(Intent.ACTION_SEND);
        i.setType("text/plain");
        i.putExtra(Intent.EXTRA_TEXT, s);
        startActivity(Intent.createChooser(i, "Partager"));
    }
}
