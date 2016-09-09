package com.hyperionstorm.snapshot.api;

import java.util.ArrayList;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;

public class WatchList
{
    protected String author = null;
    protected String[] watchList = null;
    
    public WatchList(String a)
    {
        author = a;
    }
    
    public boolean addWatch(String userId)
    {
        SnapshotApi api = SnapshotApi.getInstance();
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("author", author));
        params.add(new BasicNameValuePair("watched", userId));
        params.add(new BasicNameValuePair("code", "98098098098"));
        api.post(SnapshotApi.SERVICE_USER, UserApi.ACTION_WATCH, params, null);
        cache();
        return true;
    }

    public boolean removeWatch(String userId)
    {
        SnapshotApi api = SnapshotApi.getInstance();
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("author", author));
        params.add(new BasicNameValuePair("watched", userId));
        params.add(new BasicNameValuePair("code", "98098098098"));
        api.post(SnapshotApi.SERVICE_USER, UserApi.ACTION_UNWATCH, params, null);
        cache();
        return true;
    }
    
    public String[] getWatchList()
    {   
        cache();
        return watchList.clone();
    }
    
    protected void cache()
    {
        SnapshotApi api = SnapshotApi.getInstance();
        String[] watchListIds = null;
        byte[] results = null;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("id", author));
        params.add(new BasicNameValuePair("query", "watchlist"));
        results = api.getBytes(SnapshotApi.SERVICE_USER, UserApi.ACTION_QUERY, params);
        
        try
        {
            JSONArray watches = new JSONArray(new String(results));
            watchListIds = new String[watches.length()];
            for (int i = 0; i < watches.length(); i++)
            {
                watchListIds[i] = watches.getString(i);
            }
            
            watchList = watchListIds;
        }
        catch (JSONException e)
        {
            watchList = new String[0];
        }
    }
    

    public boolean isUserWatching(String author)
    {
        boolean found = false;
        for (String u : watchList)
        {
            if (u.equals(author))
            {
                found = true;
                break;
            }
        }
        return found;
    }
}
