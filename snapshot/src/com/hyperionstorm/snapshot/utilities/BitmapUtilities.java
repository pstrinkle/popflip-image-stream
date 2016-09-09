package com.hyperionstorm.snapshot.utilities;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class BitmapUtilities
{
    public static Bitmap loadScreenScaledBitmap(String filename, Context context){
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(filename, options);
        options.inSampleSize = calculateInSampleSize(options, context);
        options.inJustDecodeBounds = false;
        return BitmapFactory.decodeFile(filename, options);
    }
    
    public static int calculateInSampleSize(BitmapFactory.Options options, Context context) {
        int reqWidth= context.getResources().getDisplayMetrics().widthPixels;
        int reqHeight= context.getResources().getDisplayMetrics().heightPixels;
        
        // Raw height and width of image
        final int imgheight = options.outHeight;
        final int imgwidth = options.outWidth;
        int inSampleSize = 1;
    
        if (imgheight > reqHeight || imgwidth > reqWidth) {
            if (imgwidth > imgheight) {
                inSampleSize = Math.round((float)imgheight / (float)reqHeight);
            } else {
                inSampleSize = Math.round((float)imgwidth / (float)reqWidth);
            }
        }
        return inSampleSize;
    }
}
