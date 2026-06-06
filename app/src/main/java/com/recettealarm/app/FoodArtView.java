package com.recettealarm.app;

import android.content.*;import android.graphics.*;import android.view.*;

public class FoodArtView extends View{
    Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);String emoji="🍽";String label="Recette";int a=0;
    public FoodArtView(Context c){super(c);}public void setData(String e,String l){emoji=e==null?"🍽":e;label=l==null?"Recette":l;}
    protected void onDraw(Canvas c){super.onDraw(c);int w=getWidth(),h=getHeight();
        LinearGradient bg=new LinearGradient(0,0,w,h,new int[]{Color.rgb(255,248,229),Color.rgb(244,249,239),Color.rgb(231,242,234)},null,Shader.TileMode.CLAMP);
        p.setShader(bg);c.drawRoundRect(0,0,w,h,UI.dp(getContext(),30),UI.dp(getContext(),30),p);p.setShader(null);
        p.setColor(Color.argb(28,18,77,77));c.drawCircle(w*0.80f,h*0.05f,UI.dp(getContext(),80),p);p.setColor(Color.argb(22,246,198,91));c.drawCircle(w*0.10f,h*0.88f,UI.dp(getContext(),76),p);
        float cx=w/2f,cy=h*0.48f;int r=Math.min(w,h)/4;
        p.setColor(Color.WHITE);p.setShadowLayer(UI.dp(getContext(),12),0,UI.dp(getContext(),5),Color.argb(45,0,0,0));c.drawCircle(cx,cy,r+UI.dp(getContext(),12),p);p.clearShadowLayer();
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(UI.dp(getContext(),4));p.setColor(Color.rgb(14,79,79));c.drawCircle(cx,cy,r,p);p.setStyle(Paint.Style.FILL);
        p.setTextAlign(Paint.Align.CENTER);p.setTextSize(UI.dp(getContext(),44));c.drawText(emoji,cx,cy+UI.dp(getContext(),16),p);
        p.setTextSize(UI.dp(getContext(),15));p.setTypeface(Typeface.create(Typeface.DEFAULT,Typeface.BOLD));p.setColor(Color.rgb(14,79,79));c.drawText(shorten(label),cx,h-UI.dp(getContext(),22),p);p.setTypeface(Typeface.DEFAULT);
    }
    String shorten(String s){return s==null?"Recette":(s.length()>24?s.substring(0,24)+"…":s);} 
}
