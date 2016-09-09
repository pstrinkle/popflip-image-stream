package com.hyperionstorm.snapshot.guicomponents;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.support.v4.view.ViewPager;
import android.util.AttributeSet;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import com.hyperionstorm.snapshot.QueryNavigator;
import com.hyperionstorm.snapshot.R;
import com.hyperionstorm.snapshot.SnapshotGui.PostCollectionPagerAdapter;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.actions.PostView;

public class SnapshotContentView extends ImageView
{
    public SnapshotContentView(Context context)
    {
        super(context);
    }

    public SnapshotContentView(Context context, AttributeSet attrs)
    {
        super(context, attrs);
    }

    public SnapshotContentView(Context context, AttributeSet attrs,
            int defStyle)
    {
        super(context, attrs, defStyle);
    }
//    
//    public void setPostId(String postId, final QueryNavigator nav){
//        
//        class DispatchQueryExecuteTask extends AsyncTask<Void, Void, PostView> {
//            protected void onPostExecute(PostView v){
//                if(v != null)
//                {
//                    update(v);
//                }
//            }
//
//            @Override
//            protected PostView doInBackground(Void... params)
//            {
//                try
//                {
//                    return nav.getCurrentPost().getPostView();
//                }
//                catch (SnapshotApiException e)
//                {
//                    e.printStackTrace();
//                }
//                return null;
//            }
//
//        }
//        new DispatchQueryExecuteTask().execute((Void[]) null);
//        
//        Log.i("SnapshotContentView.setPostId", postId);
//    }
//    
//    public void update(PostView pv)
//    {
//        Log.i("SnapshotContentView.update", "updating post");
//        try{
//            Bitmap data = pv.getImage();
//            this.setImageBitmap(data);
//        }catch(Exception e){
//            e.printStackTrace();
//        }
//    }
}
