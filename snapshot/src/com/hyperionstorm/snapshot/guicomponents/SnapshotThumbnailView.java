package com.hyperionstorm.snapshot.guicomponents;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.os.AsyncTask;
import android.util.AttributeSet;
import android.widget.ImageView;
import android.widget.Toast;

import com.hyperionstorm.snapshot.R;
import com.hyperionstorm.snapshot.api.actions.PostView;
import com.hyperionstorm.snapshot.utilities.BitmapUtilities;

public class SnapshotThumbnailView extends ImageView
{
    private String postId = "";
    private String filename = null;
    public SnapshotThumbnailView(Context context){ super(context); }
    public SnapshotThumbnailView(Context context, AttributeSet attrs){ super(context, attrs); }
    public SnapshotThumbnailView(Context context, AttributeSet attrs, int defStyle){ super(context, attrs, defStyle); }
    private boolean loaded = false;
    
    public void setPostId(String id){
        postId = id;
    }
    
    public String getFilename(){
        return filename;
    }
    
    public void setFilename(String filename){
        this.filename = filename;
    }
    
    public String getPostId(){
        return postId;
    }
    
    @Override
    public void onDraw(Canvas canvas){
        super.onDraw(canvas);
        
//        if(!loaded){
//            final ImageView iv = (ImageView) findViewById(R.id.SnapshotContentView);
//            final String fn = filename;
//            class DispatchQueryExecuteTask extends AsyncTask<Void, Bitmap, Bitmap> {
//
//                protected void onPostExecute(Bitmap bm) {
//                    iv.setImageBitmap(bm);
//                }
//
//                @Override
//                protected Bitmap doInBackground(Void... params)
//                {
//                    if(fn == null){
//                        // fetch the image
//                    }
//                    Bitmap bm = BitmapFactory.decodeFile(fn);
//                    return bm;
//                }
//
//            }
//            new DispatchQueryExecuteTask().execute((Void[]) null);
//            
//            
//            loaded = true;
//        }
//        
//        // We want to postpone downloading the image till the draw is actually called. Load up a spinner at first.
    }
    
    public void update(PostView pv)
    {
//        try
//        {
//            final ImageView iv = (ImageView) findViewById(R.id.SnapshotContentView);
//            Bitmap data = pv.getImage();
//            iv.setImageBitmap(data);
//        }
//        catch (Exception e)
//        {
//            e.printStackTrace();
//        }
    }
}