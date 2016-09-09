package com.hyperionstorm.snapshot.api.actions;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.Random;

import org.apache.http.message.BasicNameValuePair;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.hyperionstorm.snapshot.SnapshotGui;
import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;

public class PostView extends ApiAction
{
    private static final String SnapshotsGetView = "view";
    private String postId;
    private boolean thumbnail = false;
    protected String filename;
    
    public PostView(SnapshotApi sapi, String postContentId) throws SnapshotApiException
    {   
        super(sapi);
        postId = postContentId;
        init(postContentId);
    }
    
    public PostView(SnapshotApi sapi, String postContentId, boolean isThumbnail) throws SnapshotApiException
    {   
        this(sapi, postContentId);
        thumbnail = isThumbnail;
    }
    
    private void init(String postContentId) throws SnapshotApiException{
        if (postContentId == null)
        {
            throw new SnapshotApiException(null);
        }
        
        assignFilename(postContentId);
        File f = new File(SnapshotGui.cacheDir, filename);
        
        // If the post is already in our cache, no need to refetch it.
        if(!f.exists()){
            ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
            params.add(new BasicNameValuePair("id", postContentId));
            if(isThumbnail()){
                params.add(new BasicNameValuePair("thumbnail", "true"));
            }
            byte[] rawData = SnapshotApi.getBytes(SnapshotApi.SERVICE_SNAPSHOT, SnapshotsGetView, params);
            
            BufferedOutputStream fos = null;
            try
            {
                f.createNewFile();
                fos = new BufferedOutputStream(new FileOutputStream(f));
                fos.write(rawData);
                fos.flush();
                /* make sure it can be converted to an image */
                Bitmap image = BitmapFactory.decodeByteArray(rawData, 0, rawData.length);
                if (image == null)
                {
                    throw new SnapshotApiException(new NullPointerException());
                }
                image = null;
            }
            catch (IOException e)
            {
                e.printStackTrace();
            }
            finally{
                try
                {
                    fos.close();
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
            }
        }
    }

    protected void assignFilename(String id){
        if(isThumbnail()){
            filename = "postview-cache-image-" + id + "-thumbnail.tmp";
        } else {
            filename = "postview-cache-image-" + id + ".tmp";
        }
    }
    
    protected boolean isThumbnail(){
        return thumbnail;
    }
    
    public String getFilename(){
        return filename;
    }
    
    public Bitmap getImage()
    {
        Bitmap bm = null;
        try
        {
            byte[] data = getRaw();
            bm = BitmapFactory.decodeByteArray(data, 0, data.length);
        }
        catch (SnapshotApiException e)
        {
            e.printStackTrace();
        }
        return bm;
    }

    public byte[] getRaw() throws SnapshotApiException
    {
        init(postId);
        File file = new File(SnapshotGui.cacheDir, filename);
        byte[] fileContent = null;
        try
        {
            fileContent = readFile(file);
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
        return fileContent;
    }
    
    public static byte[] readFile (File file) throws IOException {
        // Open file
        RandomAccessFile f = new RandomAccessFile(file, "r");

        try {
            // Get and check length
            long longlength = f.length();
            int length = (int) longlength;
            if (length != longlength) throw new IOException("File size >= 2 GB");

            // Read file and return data
            byte[] data = new byte[length];
            f.readFully(data);
            return data;
        }
        finally {
            f.close();
        }
    }
}