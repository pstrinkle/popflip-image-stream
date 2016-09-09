package com.hyperionstorm.snapshot.api;

import java.util.ArrayList;
import java.util.HashMap;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import com.hyperionstorm.snapshot.Log;

import android.graphics.Bitmap;

public class SnapshotApi
{
    private static SnapshotApiCreator thisSnapshotApiCreator = null;
    private static SnapshotApi thisSnapshotApi = null;


    public interface SnapshotApiCreator
    {
        public SnapshotApi create();
    }
    
    protected static void setCreator(SnapshotApiCreator testCreator)
    {
        thisSnapshotApiCreator = testCreator;
    }
    
    protected static void clearCreator()
    {
        thisSnapshotApiCreator = null;
    }
    
    /* this method is a very small hack to allow setCreator to be tested.
     * package protection should keep it generally safe.
     */
    protected static void clearInstance()
    {
        thisSnapshotApi = null;
    }

    public static SnapshotApi getInstance()
    {
        if (thisSnapshotApi == null)
        {
            if (thisSnapshotApiCreator == null)
            {
                Log.i("SnapshotApi - creating new instance");
                thisSnapshotApi = new SnapshotApi();
            }
            else
            {
                thisSnapshotApi = thisSnapshotApiCreator.create();
            }
        }
        return thisSnapshotApi;
    }
    
    protected int userId = 1;
    public static final String SERVICE_USER = "user";
    public static final String SERVICE_SNAPSHOT = "snapshot";
    public static final String ACTION_QUERY = "query";
    public static final String ACTION_HOME = "home";
    public static final String ACTION_VIEW = "view";
    public static final String ACTION_PUBLIC = "public";

    public byte[] post(
        String service,
        String action,
        ArrayList<BasicNameValuePair> params,
        HashMap<String, byte[]> multipart)
    {
        String request = HttpLib.makePostRequestUrl(service, action);
        if (multipart != null)
        {
            return HttpLib.postMultipart(request, params, multipart);
        }
        else
        {
            return HttpLib.post(request, params);
        }
    }
    
    // A somewhat sloppy way to handle upload queueing. This probably isn't good for memory management, a real queue would be handy.
    public byte[] synchronizedPost(
        String service,
        String action,
        ArrayList<BasicNameValuePair> params,
        HashMap<String, byte[]> multipart)
    {
        synchronized(this)
        {
            return post(service, action, params, multipart);
        }
    }
    
    public JSONObject getJsonObject(String service, String action, ArrayList<BasicNameValuePair> params) 
        throws SnapshotApiException
    {
         try
        {
            return new JSONObject(new String(getBytes(service, action, params)));
        }
        catch (JSONException e)
        {
            /* this is thrown when we fail to get safe data back from the
             * server, or there was a network connectivity issue.
             */
            e.printStackTrace();
            throw new SnapshotApiException(e);
        }

    }

    public static byte[] getBytes(String service, String action, ArrayList<BasicNameValuePair> params) 
    {
        String request = HttpLib.makeGetRequestUrl(service, action, params);
        return HttpLib.get(request);
    }
    
    public static byte[] getBytesForPost(String postId)
    {
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("id", postId));
        return getBytes(SERVICE_SNAPSHOT, ACTION_VIEW, params);
    }
}
