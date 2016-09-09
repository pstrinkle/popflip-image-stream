package com.hyperionstorm.snapshot.service;

import java.util.ArrayList;
import java.util.concurrent.ConcurrentLinkedQueue;

import org.apache.http.message.BasicNameValuePair;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Binder;
import android.os.IBinder;
import android.support.v4.app.NotificationCompat;
import android.widget.Toast;

import com.hyperionstorm.snapshot.Log;
import com.hyperionstorm.snapshot.NewPostActivity;
import com.hyperionstorm.snapshot.R;
import com.hyperionstorm.snapshot.Snapshot;
import com.hyperionstorm.snapshot.SnapshotGui;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.actions.Post;
import com.hyperionstorm.snapshot.utilities.ConnectionUtilities;

public class UploadService extends Service
{
    private static UploadService instance;
    private static NotificationManager mNM;
    private static ConnectivityManager connectivityManager;
    private static ConcurrentLinkedQueue<Post> postQueue = new ConcurrentLinkedQueue<Post>();
    static class PostQueueProcessor implements Runnable{
        static boolean processing = false;
        public void run(){
            processing = true;
            while(true){
                while(!ConnectionUtilities.isConnectivityAvailable(UploadService.instance)){
                    if(Snapshot.DEBUG){
                        Log.i("Waiting for internet availability");
                    }
                    try
                    {
                        Thread.sleep(5000);
                    }
                    catch (InterruptedException e)
                    {
                        Log.i("InterruptedException sleeping", e);
                        return;
                    }
                }
                
                if(postQueue.size() == 0) break;
                
                Post post = postQueue.poll();
                try
                {
                    post.submit();
                }
                catch (SnapshotApiException e)
                {
                    Log.i("API exception submitting post", e);
                }
            }
            processing = false;
            mNM.cancel(NewPostActivity.UPLOAD_NOTIFICATION);
        }
    }
    
    public void AddPost(Post post){
        postQueue.add(post);
        refreshNotification();
        
        if(!PostQueueProcessor.processing){
            PostQueueProcessor processor = new PostQueueProcessor();
            new Thread(processor).start();
        }
    }

    @Override
    public void onCreate() {
        instance = this;
        if(connectivityManager == null){
            connectivityManager = (ConnectivityManager)getSystemService(Context.CONNECTIVITY_SERVICE);
        }
        Log.i("UploadService - Got API instance");
        mNM = (NotificationManager)getSystemService(NOTIFICATION_SERVICE);

        // Display a notification about us starting.  We put an icon in the status bar.
        Toast.makeText(this, "Service started", Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onDestroy() {
        // Cancel the persistent notification.
        mNM.cancel(NewPostActivity.UPLOAD_NOTIFICATION);

        // Tell the user we stopped.
        Toast.makeText(this, "Service stopped", Toast.LENGTH_SHORT).show();
    }

    public class LocalBinder extends Binder {
        public UploadService getService() {
            return UploadService.this;
        }
    }
    
    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }
    
    public static void refreshNotification(){
        
        Intent intent = new Intent(instance, SnapshotGui.class);
        PendingIntent pIntent = PendingIntent.getActivity(instance, 0, intent, 0);
            
        Notification noti = new NotificationCompat.Builder(instance)
            .setContentTitle("Posting picture")
            .setContentText("Posts in queue: " + (postQueue.size()))
            .setSmallIcon(R.drawable.ic_launcher)
            .setContentIntent(pIntent).build();
            
        mNM.notify(NewPostActivity.UPLOAD_NOTIFICATION, noti);
    }

    private final IBinder mBinder = new LocalBinder();
}
