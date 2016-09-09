/*
 * TouchImageView.java
 * By: Michael Ortiz
 * Updated By: Patrick Lackemacher
 * Updated By: Babay88
 * -------------------
 * Extends Android ImageView to include pinch zooming and panning.
 * 
copyright (c) 2012 Michael Ortiz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

 */

package com.hyperionstorm.snapshot.guicomponents;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.graphics.drawable.Drawable;
import android.os.Environment;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.actions.Post;
import com.hyperionstorm.snapshot.api.actions.PostView;

public class TouchImageView extends ImageView {
    Matrix matrix;

    // We can be in one of these 3 states
    static final int NONE = 0;
    static final int DRAG = 1;
    static final int ZOOM = 2;
    public static boolean zoomed = false;
    public static boolean zooming = false;
    int mode = NONE;
    
    private Post post;

    // Remember some things for zooming
    PointF last = new PointF();
    PointF start = new PointF();
    float minScale = 1f;
    float maxScale = 3f;
    float[] m;


    int viewWidth, viewHeight;
    static final int CLICK = 3;
    float saveScale = 1f;
    protected float origWidth, origHeight;
    int oldMeasuredWidth, oldMeasuredHeight;


    ScaleGestureDetector mScaleDetector;

    Context context;

    public TouchImageView(Context context) {
        super(context);
        sharedConstructing(context);
        setupLongClick(context);
    }

    public TouchImageView(Context context, AttributeSet attrs) {
        super(context, attrs);
        sharedConstructing(context);
        setupLongClick(context);
    }
    
    public void setPost(Post p)
    {
        post = p;
    }
    
    private void setupLongClick(final Context context)
    {
        this.setLongClickable(true);
        this.setOnLongClickListener(new OnLongClickListener()
          {
              public boolean onLongClick(View v)
              {
                      AlertDialog.Builder myAlertDialog = new AlertDialog.Builder(context);
                      myAlertDialog.setMessage("Save Current Post Image?");
                      myAlertDialog.setPositiveButton("OK", new DialogInterface.OnClickListener()
                      {
                           public void onClick(DialogInterface arg0, int arg1)
                           {
                               saveCurrentImage();
                           }
                      });
                      
                      myAlertDialog.setNegativeButton("Cancel", new DialogInterface.OnClickListener()
                      {
                           public void onClick(DialogInterface arg0, int arg1)
                           {
                               return;
                           }
                      });
                      myAlertDialog.show();
        
                  return true;
              }
          });
    }
    
    // The current post is always cached, so just grab it from there. Only do this part if it really is missing.
    protected void saveCurrentImage()
    {
        boolean imageSaved = false;
        PostView v = null;
        Post p = post;
        try
        {
            if (p != null)
            {
                try
                {
                    v = p.getPostView();
                }
                catch (SnapshotApiException e)
                {
                    e.printStackTrace();
                    return;
                }
                if (v != null)
                {
                    File f = null;
                    try
                    {
                        f = createImageFile();
                    }
                    catch (IOException e)
                    {
                        e.printStackTrace();
                        return;
                    }
                    
                    if (f.canWrite())
                    {
                        try
                        {
                            FileOutputStream fos = new FileOutputStream(f);
                            fos.write(v.getRaw());
                            fos.close();
                            imageSaved = true;
                        }
                        catch (IOException e)
                        {
                            e.printStackTrace();
                            return;
                        }
                        catch (SnapshotApiException e)
                        {
                            e.printStackTrace();
                        }
                    }
                }
            }
        }
        finally
        {
            if(imageSaved)
            {
                Toast.makeText(this.context, "Post saved.", Toast.LENGTH_SHORT).show();
            }
            else
            {
                Toast.makeText(this.context, "Failed to save post.", Toast.LENGTH_LONG).show();
            }
        }
    }
    
    private File createImageFile() throws IOException {
        File storageDir = getAlbumDir();

        String timeStamp = 
            new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        String imageFileName = "snapshot_" + timeStamp + "_";
        File image = File.createTempFile(
            imageFileName, 
            ".jpg", 
            storageDir
        );
        
        return image;
    }
    
    private File getAlbumDir() {
        File storageDir = null;
        
        if (Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState())) {
              storageDir = new File(Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_PICTURES), "SnapshotAlbum");
              if (storageDir != null) {
                    if (! storageDir.mkdirs()) {
                          if (! storageDir.exists()){
                                return null;
                          }
                    }
              }    
        }
        return storageDir;
    }
    
    private void sharedConstructing(Context context) {
        super.setClickable(true);
        this.context = context;
        mScaleDetector = new ScaleGestureDetector(context, new ScaleListener());
        matrix = new Matrix();
        m = new float[9];
        setImageMatrix(matrix);
        setScaleType(ScaleType.MATRIX);

        setOnTouchListener(new OnTouchListener() {

            @Override
            public boolean onTouch(View v, MotionEvent event) {
                if(rotation(event))
                {
                    launchPivot = true;
                }
                
                // Multitouch session ended, and the pivot launch was activated.
                if(event.getActionMasked() == MotionEvent.ACTION_POINTER_UP && launchPivot){

                    android.util.Log.i("onTouch", "--------PIVOT------------");
                }
                
                // Make sure we're cleared out here
                if(event.getActionMasked() == MotionEvent.ACTION_POINTER_UP){
                    launchPivot = false;
                    multipass = false;
                }
                
                if(event.getActionMasked() == MotionEvent.ACTION_POINTER_UP ||
                   event.getActionMasked() == MotionEvent.ACTION_UP)
                {
                    TouchImageView.this.setLongClickable(true);
                }
                
                
                if(event.getActionMasked() == MotionEvent.ACTION_POINTER_DOWN){
                    multipass = true;
                }
                
                // Don't allow longclick while we're scrolling around the image.
                if(event.getActionMasked() == MotionEvent.ACTION_MOVE){
                    float dist = getDistance(event.getX(), event.getY(), event);
                    if(dist > 1.5)
                    {
                        TouchImageView.this.setLongClickable(false); 
                    }
                }
                
                
                
                mScaleDetector.onTouchEvent(event);
                PointF curr = new PointF(event.getX(), event.getY());

                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                    	last.set(curr);
                        start.set(last);
                        mode = DRAG;
                        break;
                        
                    case MotionEvent.ACTION_MOVE:
                        if (mode == DRAG) {
                            float deltaX = curr.x - last.x;
                            float deltaY = curr.y - last.y;
                            float fixTransX = getFixDragTrans(deltaX, viewWidth, origWidth * saveScale);
                            float fixTransY = getFixDragTrans(deltaY, viewHeight, origHeight * saveScale);
                            matrix.postTranslate(fixTransX, fixTransY);
                            fixTrans();
                            last.set(curr.x, curr.y);
                        }
                        break;

                    case MotionEvent.ACTION_UP:
                        mode = NONE;
                        int xDiff = (int) Math.abs(curr.x - start.x);
                        int yDiff = (int) Math.abs(curr.y - start.y);
                        if (xDiff < CLICK && yDiff < CLICK)
                            performClick();
                        break;

                    case MotionEvent.ACTION_POINTER_UP:
                        mode = NONE;
                        break;
                }
                
                setImageMatrix(matrix);
                invalidate();
                
                // We're handling multitouch, don't let it get passed on.
                if(!multipass){
                    return onTouchEvent(event);
                }
                else {
                    return false;
                }
            }

        });
    }
    
    private float getDistance(float startX, float startY, MotionEvent ev) {
        float distanceSum = 0;
        final int historySize = ev.getHistorySize();
        for (int h = 0; h < historySize; h++) {
            float hx = ev.getHistoricalX(0, h);
            float hy = ev.getHistoricalY(0, h);
            float dx = (hx-startX);
            float dy = (hy-startY);
            distanceSum += Math.sqrt(dx*dx+dy*dy);
            startX = hx;
            startY = hy;
        }
        float dx = (ev.getX(0)-startX);
        float dy = (ev.getY(0)-startY);
        distanceSum += Math.sqrt(dx*dx+dy*dy);
        return distanceSum;        
    }

    public void setMaxZoom(float x) {
        maxScale = x;
    }

    private class ScaleListener extends ScaleGestureDetector.SimpleOnScaleGestureListener {
        @Override
        public boolean onScaleBegin(ScaleGestureDetector detector) {
            mode = ZOOM;
            TouchImageView.this.setLongClickable(false);
            return true;
        }
        
        @Override
        public void onScaleEnd(ScaleGestureDetector detector) {
            super.onScaleEnd(detector);
            TouchImageView.this.setLongClickable(true);
        }

        @Override
        public boolean onScale(ScaleGestureDetector detector) {
            float mScaleFactor = detector.getScaleFactor();
            float origScale = saveScale;
            saveScale *= mScaleFactor;
            if (saveScale > maxScale) {
                saveScale = maxScale;
                mScaleFactor = maxScale / origScale;
            } else if (saveScale < minScale) {
                saveScale = minScale;
                mScaleFactor = minScale / origScale;
            }

            if (origWidth * saveScale <= viewWidth || origHeight * saveScale <= viewHeight)
                matrix.postScale(mScaleFactor, mScaleFactor, viewWidth / 2, viewHeight / 2);
            else
                matrix.postScale(mScaleFactor, mScaleFactor, detector.getFocusX(), detector.getFocusY());

            if(saveScale == minScale)
            {
                ToggledViewPager.enabled = true;
                //zoomed = false;
            }
            else
            {
                ToggledViewPager.enabled = false;
                //zoomed = true;
            }
            
            fixTrans();
            return true;
        }
    }

    void fixTrans() {
        matrix.getValues(m);
        float transX = m[Matrix.MTRANS_X];
        float transY = m[Matrix.MTRANS_Y];
        
        float fixTransX = getFixTrans(transX, viewWidth, origWidth * saveScale);
        float fixTransY = getFixTrans(transY, viewHeight, origHeight * saveScale);

        if (fixTransX != 0 || fixTransY != 0)
            matrix.postTranslate(fixTransX, fixTransY);
    }

    float getFixTrans(float trans, float viewSize, float contentSize) {
        float minTrans, maxTrans;

        if (contentSize <= viewSize) {
            minTrans = 0;
            maxTrans = viewSize - contentSize;
        } else {
            minTrans = viewSize - contentSize;
            maxTrans = 0;
        }

        if (trans < minTrans)
            return -trans + minTrans;
        if (trans > maxTrans)
            return -trans + maxTrans;
        return 0;
    }
    
    float getFixDragTrans(float delta, float viewSize, float contentSize) {
        if (contentSize <= viewSize) {
            return 0;
        }
        return delta;
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        viewWidth = MeasureSpec.getSize(widthMeasureSpec);
        viewHeight = MeasureSpec.getSize(heightMeasureSpec);
        
        if (oldMeasuredHeight == viewWidth && oldMeasuredHeight == viewHeight
                || viewWidth == 0 || viewHeight == 0)
            return;
        oldMeasuredHeight = viewHeight;
        oldMeasuredWidth = viewWidth;

        if (saveScale == 1) {
            //Fit to screen.
            float scale;

            Drawable drawable = getDrawable();
            if (drawable == null || drawable.getIntrinsicWidth() == 0 || drawable.getIntrinsicHeight() == 0)
                return;
            int bmWidth = drawable.getIntrinsicWidth();
            int bmHeight = drawable.getIntrinsicHeight();

            float scaleX = (float) viewWidth / (float) bmWidth;
            float scaleY = (float) viewHeight / (float) bmHeight;
            scale = Math.min(scaleX, scaleY);
            matrix.setScale(scale, scale);

            // Center the image
            float redundantYSpace = (float) viewHeight - (scale * (float) bmHeight);
            float redundantXSpace = (float) viewWidth - (scale * (float) bmWidth);
            redundantYSpace /= (float) 2;
            redundantXSpace /= (float) 2;

            matrix.postTranslate(redundantXSpace, redundantYSpace);

            origWidth = viewWidth - 2 * redundantXSpace;
            origHeight = viewHeight - 2 * redundantYSpace;
            setImageMatrix(matrix);
        }
        fixTrans();
    }
    
    private double startAngle = Double.MIN_VALUE;
    private boolean launchPivot = false;
    private boolean multipass = false;
    private int smoother = 0;
    
    private boolean rotation(MotionEvent event) { 
        try{
        double delta_x = (event.getX(0) - event.getX(1));
        double delta_y = (event.getY(0) - event.getY(1));
        double radians = Math.atan2(delta_y, delta_x); 
        if(startAngle == Double.MIN_VALUE){
            startAngle = Math.toDegrees(radians);
        }
        double distance = Math.abs(startAngle - Math.toDegrees(radians));

        if(distance > 45){
            if(smoother == 10){
                return true;
            }
            smoother++;
        } else {
            smoother = 0;
        }
        }
        catch(Exception e)
        {
            
        }
        return false;
    }
}