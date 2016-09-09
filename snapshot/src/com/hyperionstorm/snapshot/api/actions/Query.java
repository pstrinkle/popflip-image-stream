package com.hyperionstorm.snapshot.api.actions;

import java.util.ArrayList;
import java.util.List;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;


public class Query extends ApiAction
{
    private static final String SnapshotsGetHome = "home";
    private ArrayList<Post> posts = new ArrayList<Post>();
    /* for later, when we need to requery to get more results */
    private ArrayList<BasicNameValuePair> sourceFactors = null;
    
    protected JSONArray sourceJson = null;
    
    public enum QueryType {
        QUERY_TYPE_HOME,
        QUERY_TYPE_NORM,
        QUERY_TYPE_PUBLIC
    };

    public Query(
        SnapshotApi sapi,
        ArrayList<BasicNameValuePair> factors,
        QueryType qt) 
        throws SnapshotApiException
    {
        super(sapi);
        
        /* for some reason, I don't think this is safe. caller could change
         * the provided data in factors, and that would update here maybe.
         */
        sourceFactors = factors;
        byte[] data = null;
        if (qt == QueryType.QUERY_TYPE_HOME)
        {
            data = api.getBytes(SnapshotApi.SERVICE_SNAPSHOT, SnapshotsGetHome, factors);
        }
        else if (qt == QueryType.QUERY_TYPE_NORM)
        {
            data = api.getBytes(SnapshotApi.SERVICE_SNAPSHOT, SnapshotApi.ACTION_QUERY, factors);
        }
        else if (qt == QueryType.QUERY_TYPE_PUBLIC)
        {
            data = api.getBytes(SnapshotApi.SERVICE_SNAPSHOT, SnapshotApi.ACTION_PUBLIC, factors);
        }
        else
        {
            throw new SnapshotApiException(null);
        }
        
        try
        {
            String jsonStringData = new String(data);
            /* first try the array of posts */
            sourceJson = new JSONArray(jsonStringData);
            
            /* now try to break out each one into a post object */
            for (int i = 0; i < sourceJson.length(); i++)
            {
                try
                {
                    JSONObject post = new JSONObject(sourceJson.getString(i));
                    posts.add(new Post(api, post));
                }
                catch (JSONException e)
                {
                    /* no need to terminate, maybe there are good posts later! */
                    e.printStackTrace();
                }
            }
        }
        catch (JSONException e)
        {
            e.printStackTrace();
            throw new SnapshotApiException(e);
        }
    }

    public Post getPost(int i)
    {
        try
        {
            return posts.get(i);
        }
        catch (Exception e)
        {
            e.printStackTrace();
            return null;
        }
    }
    
    public List<String> getPostIds(){
        ArrayList<String> ids = new ArrayList<String>();
        for(Post post : posts){
            ids.add(post.getPostId());
        }
        return ids;
    }
    
    public int count()
    {
        return posts.size();
    }

    public ArrayList<BasicNameValuePair> getSourceFactors()
    {
        return sourceFactors;
    }

    public void cleanup()
    {
        for (Post p : posts)
        {
            p.cleanup();
        }
    }
}
