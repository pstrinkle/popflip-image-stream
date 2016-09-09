package com.hyperionstorm.snapshot.api.actions;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.TimeZone;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;

import com.hyperionstorm.snapshot.Log;
import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.UserApi;


public class Post extends ApiAction
{
    private static final String SnapshotsGetPost = "get?";
    
    /* fields for when this is a submitted post */
    protected boolean createdPost = false;
    protected String postPath = null;
    protected ArrayList<BasicNameValuePair> postParams = new ArrayList<BasicNameValuePair>();
    
    private JSONObject sourceJson = null;
    private String postContentId = null;
    private String authorId = null;
    private Date created = null;
    private int numReplies = 0;
    private final ArrayList<String> tags = new ArrayList<String>();
    private boolean isReply = false;
    private PostView myPostView = null;
    private Semaphore loadSema = null;

    private String repostOfId;
    private boolean isRepost;
    private boolean isFavorited = false;
    
    /* for testing */
    public boolean isCached()
    {
        return myPostView != null ? true : false;
    }
    
    protected void extractFields() throws JSONException
    {
        /* basic unpacking of the object */
        JSONArray sourceTags = null;
        postContentId = sourceJson.getString("id");
        setCreationDate(sourceJson.getString("created"));
        setAuthorId(sourceJson.getString("author"));
        setNumReplies(sourceJson.getInt("num_replies"));
        sourceTags = sourceJson.getJSONArray("tags");
        for (int i = 0; i < sourceTags.length(); i++)
        {
            tags.add(sourceTags.getString(i));
        }
        
        try
        {
            isFavorited = sourceJson.getBoolean("favorite_of_user");
        }
        catch(JSONException e)
        {
            /* no big deal */
        }
    }
    
    public Post(SnapshotApi sapi, String postId)
        throws SnapshotApiException
    {
        super(sapi);
        if (postId == null)
        {
            throw new SnapshotApiException(null);
        }
        loadSema  = new Semaphore(1);
        
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("id", postId));

        sourceJson = api.getJsonObject(SnapshotApi.SERVICE_SNAPSHOT, SnapshotsGetPost, params);

        try
        {
            extractFields();
        }
        catch (Exception e)
        {
            Log.i("API exception posting", e);
            throw new SnapshotApiException(e);
        }

    }
    
    public Post(SnapshotApi sapi, JSONObject json)
        throws SnapshotApiException
    {
        super(sapi);
        loadSema  = new Semaphore(1);
        sourceJson = json;

        try
        {
            extractFields();
        }
        catch (Exception e)
        {
            Log.i("API exception posting", e);
            throw new SnapshotApiException(e);
        }
    }
    
    public Post(SnapshotApi sapi,
            ArrayList<String> postTags,
            String repliedToPostId,
            String postLocation) throws SnapshotApiException
    {
        super(sapi);
        String tagsList = "";
        createdPost = true;
        loadSema  = new Semaphore(1);

        for (String tag : postTags)
        {
            tagsList += (tag + ",");
        }
        if (tagsList != "")
        {
            /* truncate the last comma */ 
            tagsList = tagsList.substring(0, tagsList.length() - 1);
        }
        
        if (repliedToPostId != null)
        {
            postParams.add(new BasicNameValuePair("reply_to", repliedToPostId));
            isReply = true;
        }
        
        postParams.add(new BasicNameValuePair("author", UserApi.getInstance().getCurrentUserId()));
        postParams.add(new BasicNameValuePair("tags", tagsList));
        if (postLocation != null)
        {
            postParams.add(new BasicNameValuePair("location", postLocation));
        }
        postParams.add(new BasicNameValuePair("code", "98098098098"));
    }
    
    public Post(SnapshotApi sapi, ArrayList<String> postTags, String repliedToPostId,
            String postLocation, String repostOfId) throws SnapshotApiException
    {
        super(sapi);
        
        this.repostOfId = repostOfId;
        String tagsList = "";
        createdPost = true;
        loadSema  = new Semaphore(1);

        for (String tag : postTags)
        {
            tagsList += (tag + ",");
        }
        if (tagsList != "")
        {
            /* truncate the last comma */ 
            tagsList = tagsList.substring(0, tagsList.length() - 1);
        }
        
        if (repostOfId != null)
        {
            this.repostOfId = repostOfId;
            postParams.add(new BasicNameValuePair("repost_of", this.repostOfId));
            isRepost = true;
        }
        
        if (repliedToPostId != null)
        {
            postParams.add(new BasicNameValuePair("reply_to", repliedToPostId));
            isReply = true;
        }
        
        postParams.add(new BasicNameValuePair("author", "501c4ff35e358e797d000002"));
        postParams.add(new BasicNameValuePair("tags", tagsList));
        if (postLocation != null)
        {
            postParams.add(new BasicNameValuePair("location", postLocation));
        }
        postParams.add(new BasicNameValuePair("code", "98098098098"));
    }

    public void addContent(String postPath)
    {
        if (createdPost)
        {
            this.postPath = postPath;
        }
    }
    
    public JSONObject submit() throws SnapshotApiException
    {
        byte[] postOutput = null;
        JSONObject resultId = null;
        HashMap<String, byte[]> multipart = new HashMap<String, byte[]>();
        
        Bitmap bm = BitmapFactory.decodeFile(postPath);
        int width = bm.getWidth();
        int height = bm.getHeight();
        
        if(width > 1024 || height > 1024)
        {
            boolean portrait = width > height;
            
            double factor = 0;
            if(portrait)
            {
                int newwidth = 1024;
                factor = (double)newwidth / (double)width;
                width = newwidth;
                height = (int) (height*factor);
            }
            else
            {
                int newheight = 1024;
                factor = (double)newheight / (double)height;
                height = newheight;
                width = (int) (width*factor);
            }
        }
        
        bm = getResizedBitmap(bm, height, width);
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.JPEG, 90, os);
        try
        {
            os.close();
            byte[] array = os.toByteArray();
            Log.i("submit image - JPEG is " + Integer.toString(array.length) + "bytes");
            multipart.put("data", array);
            
            if (createdPost)
            {
                if (isReply)
                {
                    postOutput = api.post(SnapshotApi.SERVICE_SNAPSHOT, "reply", postParams, multipart);
                }
                else if (isRepost)
                {
                    postOutput = api.post(SnapshotApi.SERVICE_SNAPSHOT, "repost", postParams, null);
                }
                else
                {
                    postOutput = api.post(SnapshotApi.SERVICE_SNAPSHOT, "create", postParams, multipart);
                }
            }
            resultId = new JSONObject(new String(postOutput));
        }
        catch (IOException e)
        {
            Log.i("IOException submitting image", e);
        }
        catch (JSONException e)
        {
            Log.i("JSONException parsing response", e);
        }
        return resultId;
    }
    
    /*
     * Takes a name for a file to upload with the post.
     */
    public JSONObject submit(String filename) throws SnapshotApiException, IOException
    {
        byte[] postOutput = null;
        JSONObject resultId = null;
        HashMap<String, byte[]> multipart = new HashMap<String, byte[]>();
        
        RandomAccessFile f = new RandomAccessFile(filename, "r");
        byte[] bytes = new byte[(int)f.length()];
        f.read(bytes);
        f.close();
        
        multipart.put("data", bytes);
        if (createdPost)
        {
            if (isReply)
            {
                postOutput = api.post(SnapshotApi.SERVICE_SNAPSHOT, "reply", postParams, multipart);
            }
            else if (isRepost)
            {
                postOutput = api.post(SnapshotApi.SERVICE_SNAPSHOT, "repost", postParams, null);
            }
            else
            {
                postOutput = api.post(SnapshotApi.SERVICE_SNAPSHOT, "create", postParams, multipart);
            }
        }
        try
        {
            resultId = new JSONObject(new String(postOutput));
        }
        catch (JSONException e)
        {
            Log.i("JSONException parsing response", e);
        }
        return resultId;
    }
    
    public String getPostId()
    {
        return postContentId;
    }
    
    /* for debug, remove eventually */
    public String getPostJson()
    {
        return sourceJson.toString();
    }
    
    @SuppressWarnings("unchecked")
    public ArrayList<String> getTags()
    {
        return (ArrayList<String>) tags.clone();
    }

    public String getAuthor()
    {
        return authorId;
    }
    
    private void setCreationDate(String createdate)
    {
    	
    	SimpleDateFormat formatter = new SimpleDateFormat("E MMM dd HH:mm:ss yyyy");
    	try {
    		// Parse the date and adjust for daylight savings and UTC offset.
			Date createdDate = (Date) formatter.parse(createdate);
			long offset = TimeZone.getDefault().getRawOffset();
			
			if(TimeZone.getDefault().inDaylightTime(createdDate))
			{
				offset += (1000*60*60);
			}
			
			this.created = new Date(createdDate.getTime() + offset);
		} catch (ParseException e) {
		    Log.i("ParseException setting creation date", e);
		}
    }
    
    public Date getCreationDate()
    {
    	return this.created;
    }

    private void setAuthorId(String authorId)
    {
        this.authorId = authorId;
    }

    public boolean hasReplies()
    {
        if (numReplies != 0)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    private void setNumReplies(int hasReplies)
    {
        this.numReplies = hasReplies;
    }
    
    /* should be called by an AsyncTask or other thread */
    public void cleanup()
    {
        try
        {
            /* unlike the others, this one can block indefinitely */
            loadSema.acquire();
            myPostView = null;
        }
        catch (InterruptedException e)
        {
            Log.i("InterruptedException during cleanup", e);
        }
        finally
        {
            loadSema.release();
        }
    }
    
    /* should be called by an AsyncTask or other thread */
    public void cache()
    {
        boolean acquired = false;
        /* don't even try if the image is already loaded */
        if (myPostView == null)
        {
            try
            {
                /* try to acquire the lock in 5 seconds */
                acquired = loadSema.tryAcquire(5, TimeUnit.SECONDS);
                myPostView = new PostView(api, postContentId);
            }
            catch (InterruptedException e)
            {
                /* not sure what to do here yet... try again?
                 * I suspect this might cause us to freeze.
                 */ 
                Log.i("InterruptedException doing cache", e);
                cache();
            }
            catch (SnapshotApiException e)
            {
                e.printStackTrace();
            }
            finally
            {
                if (acquired == true)
                {
                    loadSema.release();
                }
            }
        }
    }
    
    public PostView getPostView() throws SnapshotApiException
    {
        PostView npv = null;
        boolean acquired = false;
        
        if (myPostView == null)
        {
            /* try to synchronously load the post content */
            try
            {
                acquired = loadSema.tryAcquire(2,TimeUnit.SECONDS);
                if (acquired)
                {
                    /* need to check again if the cache occurred afore the wait */
                    if (myPostView == null)
                    {
                        npv = new PostView(api, postContentId);
                        myPostView = npv;
                    }
                }
                else
                {
                    /* lock not acquired, so the cache function is running.
                     * return null to the caller - that should signal to the
                     * caller to try again soon
                     */
                    return null;
                }
            }
            catch (SnapshotApiException e)
            {
                Log.i("API exception getting postview", e);
                throw new SnapshotApiException(e);
            }
            catch (InterruptedException e)
            {
                Log.i("InterruptedException getting postview", e);
                throw new SnapshotApiException(e);
            }
            finally
            {
                if (acquired)
                {
                    loadSema.release();
                }
            }
        }
        
        return myPostView;
    }

    public boolean isFavorited()
    {
        return isFavorited ;
    }

    public void unfavorite()
    {
        isFavorited = false;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("user", UserApi.getInstance().getCurrentUserId()));
        params.add(new BasicNameValuePair("post", getPostId()));
        api.post(SnapshotApi.SERVICE_SNAPSHOT, "unfavorite", params, null);
    }

    public void favorite()
    {   
        isFavorited = true;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("user", UserApi.getInstance().getCurrentUserId()));
        params.add(new BasicNameValuePair("post", getPostId()));
        api.post(SnapshotApi.SERVICE_SNAPSHOT, "favorite", params, null);
    }
    
    public static Bitmap getResizedBitmap(Bitmap bm, int newHeight, int newWidth) {
        int width = bm.getWidth();
        int height = bm.getHeight();
        float scaleWidth = ((float) newWidth) / width;
        float scaleHeight = ((float) newHeight) / height;
        // CREATE A MATRIX FOR THE MANIPULATION
        Matrix matrix = new Matrix();
        // RESIZE THE BIT MAP
        matrix.postScale(scaleWidth, scaleHeight);


        // RECREATE THE NEW BITMAP
        Bitmap resizedBitmap = Bitmap.createBitmap(bm, 0, 0, width, height, matrix, false);
        return resizedBitmap;
    }
}
