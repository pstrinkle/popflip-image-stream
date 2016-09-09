package com.hyperionstorm.snapshot.guicomponents;

import android.content.Context;
import android.graphics.Color;
import android.support.v4.view.ViewPager;
import android.util.AttributeSet;
import android.view.MotionEvent;

public class ToggledViewPager extends ViewPager
{
    public static boolean enabled = true;
    
    public ToggledViewPager(Context context)
    {
        super(context);
    }
    
    public ToggledViewPager(Context context, AttributeSet attrs)
    {
        super(context, attrs);
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        if (enabled) {
            return super.onInterceptTouchEvent(event);
        }
 
        return false;
    }
}
