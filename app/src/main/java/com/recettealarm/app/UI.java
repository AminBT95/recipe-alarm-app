package com.recettealarm.app;

import android.app.*;import android.content.*;import android.graphics.*;import android.graphics.drawable.*;import android.net.*;import android.text.InputType;import android.view.*;import android.widget.*;

public class UI{
 static int terracotta=Color.rgb(181,92,49),terracotta2=Color.rgb(219,128,78),dark=Color.rgb(45,35,29),muted=Color.rgb(119,100,87),cream=Color.rgb(255,248,239),soft=Color.rgb(248,238,226),olive=Color.rgb(111,128,72),danger=Color.rgb(190,41,33),gold=Color.rgb(235,169,61),green=Color.rgb(81,128,88);
 static int dp(Context c,int v){return (int)(v*c.getResources().getDisplayMetrics().density+0.5f);} 
 static GradientDrawable bg(int color,int radius){GradientDrawable g=new GradientDrawable();g.setColor(color);g.setCornerRadius(radius);return g;}
 static GradientDrawable stroke(Context c,int color,int radius,int sc){GradientDrawable g=bg(color,radius);g.setStroke(dp(c,1),sc);return g;}
 static GradientDrawable grad(int c1,int c2,int radius){GradientDrawable g=new GradientDrawable(GradientDrawable.Orientation.TL_BR,new int[]{c1,c2});g.setCornerRadius(radius);return g;}
 static TextView tv(Context c,String t,int sp,int style){TextView v=new TextView(c);v.setText(t==null?"":t);v.setTextSize(sp);v.setTypeface(Typeface.DEFAULT,style);v.setTextColor(dark);v.setPadding(dp(c,6),dp(c,5),dp(c,6),dp(c,5));v.setLineSpacing(dp(c,2),1.08f);return v;}
 static TextView muted(Context c,String t,int sp){TextView v=tv(c,t,sp,Typeface.NORMAL);v.setTextColor(muted);return v;}
 static TextView center(Context c,String t,int sp,int style){TextView v=tv(c,t,sp,style);v.setGravity(Gravity.CENTER);return v;}
 static Button btn(Context c,String t){Button b=new Button(c);b.setText(t);b.setAllCaps(false);b.setTextColor(Color.WHITE);b.setTextSize(15);b.setTypeface(Typeface.DEFAULT,Typeface.BOLD);b.setPadding(dp(c,12),dp(c,12),dp(c,12),dp(c,12));b.setBackground(grad(terracotta,terracotta2,dp(c,24)));LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,dp(c,56));lp.setMargins(0,dp(c,7),0,dp(c,7));b.setLayoutParams(lp);return b;}
 static Button whiteBtn(Context c,String t){Button b=btn(c,t);b.setTextColor(dark);b.setBackground(stroke(c,Color.WHITE,dp(c,24),Color.rgb(236,222,207)));return b;}
 static Button oliveBtn(Context c,String t){Button b=btn(c,t);b.setBackground(grad(olive,Color.rgb(139,153,82),dp(c,24)));return b;}
 static Button dangerBtn(Context c,String t){Button b=btn(c,t);b.setBackground(grad(danger,Color.rgb(218,80,55),dp(c,24)));return b;}
 static EditText input(Context c,String h){EditText e=new EditText(c);e.setHint(h);e.setTextSize(15);e.setTextColor(dark);e.setHintTextColor(Color.rgb(159,143,130));e.setSingleLine(false);e.setMinLines(1);e.setPadding(dp(c,16),dp(c,12),dp(c,16),dp(c,12));e.setBackground(stroke(c,Color.WHITE,dp(c,18),Color.rgb(236,224,211)));LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2);lp.setMargins(0,dp(c,6),0,dp(c,8));e.setLayoutParams(lp);return e;}
 static EditText area(Context c,String h){EditText e=input(c,h);e.setMinLines(3);e.setGravity(Gravity.TOP);return e;}
 static EditText number(Context c,String h){EditText e=input(c,h);e.setInputType(InputType.TYPE_CLASS_NUMBER|InputType.TYPE_NUMBER_FLAG_DECIMAL);return e;}
 static LinearLayout root(Activity a){ScrollView sv=new ScrollView(a);sv.setFillViewport(true);LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.VERTICAL);l.setPadding(dp(a,20),dp(a,24),dp(a,20),dp(a,30));l.setBackgroundColor(cream);sv.addView(l,new ScrollView.LayoutParams(-1,-2));a.setContentView(sv);return l;}
 static LinearLayout row(Context c){LinearLayout l=new LinearLayout(c);l.setOrientation(LinearLayout.HORIZONTAL);l.setGravity(Gravity.CENTER_VERTICAL);return l;}
 static LinearLayout section(Context c){LinearLayout box=new LinearLayout(c);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(dp(c,18),dp(c,16),dp(c,18),dp(c,16));box.setBackground(stroke(c,Color.WHITE,dp(c,30),Color.rgb(238,226,213)));LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2);lp.setMargins(0,dp(c,10),0,dp(c,14));box.setLayoutParams(lp);return box;}
 static LinearLayout hero(Context c,String icon,String title,String sub){LinearLayout h=section(c);h.setBackground(grad(Color.rgb(255,235,214),Color.rgb(255,247,238),dp(c,34)));TextView ic=center(c,icon,46,Typeface.BOLD);h.addView(ic);h.addView(center(c,title,20,Typeface.BOLD));h.addView(center(c,sub,14,Typeface.NORMAL));return h;}
 static TextView chip(Context c,String t,boolean active){TextView v=center(c,t,14,Typeface.BOLD);v.setTextColor(active?Color.WHITE:dark);v.setBackground(active?grad(terracotta,terracotta2,dp(c,40)):stroke(c,Color.WHITE,dp(c,40),Color.rgb(236,222,207)));LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-2,dp(c,45));lp.setMargins(0,dp(c,5),dp(c,10),dp(c,8));v.setMinWidth(dp(c,94));v.setGravity(Gravity.CENTER);v.setLayoutParams(lp);return v;}
 static TextView card(Context c,String t){TextView v=tv(c,t,16,Typeface.BOLD);v.setBackground(stroke(c,Color.WHITE,dp(c,28),Color.rgb(239,228,215)));v.setPadding(dp(c,18),dp(c,16),dp(c,18),dp(c,16));LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2);lp.setMargins(0,dp(c,7),0,dp(c,9));v.setLayoutParams(lp);return v;}
 static TextView smallCard(Context c,String t){TextView v=card(c,t);v.setTextSize(15);v.setTypeface(Typeface.DEFAULT,Typeface.NORMAL);return v;}
 static TextView pill(Context c,String t,int color){TextView v=center(c,t,13,Typeface.BOLD);v.setTextColor(Color.WHITE);v.setBackground(bg(color,dp(c,26)));v.setPadding(dp(c,12),dp(c,7),dp(c,12),dp(c,7));return v;}
 static ImageView image(Context c,String uri,int h){ImageView iv=new ImageView(c);iv.setScaleType(ImageView.ScaleType.CENTER_CROP);iv.setBackground(bg(Color.rgb(242,229,214),dp(c,26)));iv.setPadding(dp(c,0),dp(c,0),dp(c,0),dp(c,0));LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,dp(c,h));lp.setMargins(0,dp(c,8),0,dp(c,10));iv.setLayoutParams(lp);try{if(uri!=null&&uri.trim().length()>0)iv.setImageURI(Uri.parse(uri));else iv.setImageResource(android.R.drawable.ic_menu_gallery);}catch(Exception e){iv.setImageResource(android.R.drawable.ic_menu_gallery);}return iv;}
 static String stars(int r){if(r<0)r=0;if(r>5)r=5;String s="";for(int i=1;i<=5;i++)s+=i<=r?"★":"☆";return s;}
 static void toast(Context c,String s){Toast.makeText(c,s,Toast.LENGTH_SHORT).show();}
}
