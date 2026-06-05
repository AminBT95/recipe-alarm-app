package com.recettealarm.app;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.text.InputType;
import android.view.*;
import android.widget.*;

public class UI {
    static int brown = Color.rgb(169, 84, 45);
    static int dark = Color.rgb(45, 39, 35);
    static int cream = Color.rgb(255, 250, 244);
    static int soft = Color.rgb(246, 239, 231);
    static int olive = Color.rgb(116, 133, 62);
    static int danger = Color.rgb(194, 30, 30);

    static int dp(Context c, int v) {
        return (int) (v * c.getResources().getDisplayMetrics().density + 0.5f);
    }

    static GradientDrawable bg(int color, int radius) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(color);
        g.setCornerRadius(radius);
        return g;
    }

    static GradientDrawable stroke(int color, int radius, int strokeColor) {
        GradientDrawable g = bg(color, radius);
        g.setStroke(1, strokeColor);
        return g;
    }

    static TextView tv(Context c, String t, int sp, int style) {
        TextView v = new TextView(c);
        v.setText(t == null ? "" : t);
        v.setTextSize(sp);
        v.setTypeface(Typeface.DEFAULT, style);
        v.setTextColor(dark);
        v.setPadding(dp(c, 8), dp(c, 6), dp(c, 8), dp(c, 6));
        v.setLineSpacing(dp(c, 2), 1.05f);
        return v;
    }

    static TextView center(Context c, String t, int sp, int style) {
        TextView v = tv(c, t, sp, style);
        v.setGravity(Gravity.CENTER);
        return v;
    }

    static Button btn(Context c, String t) {
        Button b = new Button(c);
        b.setText(t);
        b.setTextColor(Color.WHITE);
        b.setTextSize(15);
        b.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        b.setAllCaps(false);
        b.setPadding(dp(c, 12), dp(c, 12), dp(c, 12), dp(c, 12));
        b.setBackground(bg(brown, dp(c, 26)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, dp(c, 58));
        lp.setMargins(0, dp(c, 8), 0, dp(c, 8));
        b.setLayoutParams(lp);
        return b;
    }

    static Button whiteBtn(Context c, String t) {
        Button b = btn(c, t);
        b.setTextColor(dark);
        b.setBackground(stroke(Color.WHITE, dp(c, 26), Color.rgb(232, 222, 211)));
        return b;
    }

    static EditText input(Context c, String h) {
        EditText e = new EditText(c);
        e.setHint(h);
        e.setTextSize(15);
        e.setSingleLine(false);
        e.setMinLines(1);
        e.setTextColor(dark);
        e.setHintTextColor(Color.rgb(170, 158, 148));
        e.setPadding(dp(c, 16), dp(c, 10), dp(c, 16), dp(c, 10));
        e.setBackground(stroke(Color.WHITE, dp(c, 14), Color.rgb(230, 220, 209)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.setMargins(0, dp(c, 7), 0, dp(c, 7));
        e.setLayoutParams(lp);
        return e;
    }

    static EditText number(Context c, String h) {
        EditText e = input(c, h);
        e.setInputType(InputType.TYPE_CLASS_NUMBER);
        return e;
    }

    static LinearLayout root(Activity a) {
        ScrollView sv = new ScrollView(a);
        sv.setFillViewport(true);
        LinearLayout l = new LinearLayout(a);
        l.setOrientation(LinearLayout.VERTICAL);
        l.setPadding(dp(a, 22), dp(a, 26), dp(a, 22), dp(a, 26));
        l.setBackgroundColor(cream);
        sv.addView(l, new ScrollView.LayoutParams(-1, -2));
        a.setContentView(sv);
        return l;
    }

    static LinearLayout section(Context c) {
        LinearLayout box = new LinearLayout(c);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(c, 18), dp(c, 16), dp(c, 18), dp(c, 16));
        box.setBackground(stroke(Color.WHITE, dp(c, 28), Color.rgb(238, 228, 217)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.setMargins(0, dp(c, 10), 0, dp(c, 14));
        box.setLayoutParams(lp);
        return box;
    }

    static TextView chip(Context c, String t) {
        TextView v = center(c, t, 14, Typeface.BOLD);
        v.setTextColor(Color.WHITE);
        v.setBackground(bg(brown, dp(c, 40)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-2, dp(c, 48));
        lp.setMargins(0, dp(c, 5), dp(c, 10), dp(c, 8));
        v.setMinWidth(dp(c, 105));
        v.setGravity(Gravity.CENTER);
        v.setLayoutParams(lp);
        return v;
    }

    static TextView card(Context c, String t) {
        TextView v = tv(c, t, 17, Typeface.BOLD);
        v.setBackground(stroke(Color.WHITE, dp(c, 30), Color.rgb(239, 230, 220)));
        v.setPadding(dp(c, 22), dp(c, 18), dp(c, 22), dp(c, 18));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.setMargins(0, dp(c, 8), 0, dp(c, 10));
        v.setLayoutParams(lp);
        return v;
    }

    static TextView smallCard(Context c, String t) {
        TextView v = card(c, t);
        v.setTextSize(15);
        v.setTypeface(Typeface.DEFAULT, Typeface.NORMAL);
        return v;
    }

    static void toast(Context c, String s) {
        Toast.makeText(c, s, Toast.LENGTH_SHORT).show();
    }
}
