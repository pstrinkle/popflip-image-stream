package com.hyperionstorm.snapshot.api.actions;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;

import junit.framework.Assert;
import junit.framework.TestCase;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;

public class PostTest extends TestCase
{

    private boolean locationExpected;
    private class PostTestSnapshotApi extends SnapshotApi
    {

        @Override
        public JSONObject getJsonObject(
            String service,
            String cmd, ArrayList<BasicNameValuePair> params)
        {
            /* make sure we are sending sane stuff */
            /*
            Assert.assertEquals(cmd, "get?");
            Assert.assertTrue(params.containsKey("id"));
            Assert.assertNotNull(params.get("id"));*/
            
            /* verify we can parse the output */
            try
            {
                String id = null;
                for (BasicNameValuePair p : params)
                {
                    if (p.getName() == "id")
                    {
                        id = p.getValue();
                        break;
                    }
                }
                if (id == testPostIdReplies)
                {
                    return new JSONObject(testPostStringWithReplies);
                }
                if (id == testPostIdNoReplies)
                {
                    return new JSONObject(testPostStringNoReplies);
                }
                if (id == testPostIdFavFalse)
                {
                    return new JSONObject(testPostStringWithFavFalse);
                }
                if (id == testPostIdFavTrue)
                {
                    return new JSONObject(testPostStringWithFavTrue);
                }
            }
            catch (JSONException e)
            {
                Assert.fail("Static test content failed to be parsed.");
            }
            Assert.fail("Invalid test parameters?");
            return null;
        }

        @Override
        public byte[] getBytes(String service, String cmd, ArrayList<BasicNameValuePair> params)
        {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Bitmap b = Bitmap.createBitmap(500, 500, Bitmap.Config.ARGB_8888);
            b.compress(CompressFormat.PNG, 100, baos);
            byte[] data = baos.toByteArray();
            return data;
        }
        
        @Override
        public byte[] post(
            String service,
            String action,
            ArrayList<BasicNameValuePair> params, HashMap<String, byte[]> d)
        {
            if (action.equals("unfavorite") ||
                action.equals("favorite"))
            {
                boolean userFound = false;
                boolean postFound = false;
                for (BasicNameValuePair p : params)
                {
                    if (p.getName() == "user")
                    {
                        userFound = true;
                    }
                    
                    if (p.getName() == "post")
                    {
                        postFound = true;
                    }
                }
                assertTrue(userFound);
                assertTrue(postFound);
                return null;
            }
            
            if (
                action.equals("repost") || 
                action.equals("reply") || 
                action.equals("create"))
            {
                
            }
            else
            {
                Assert.fail("api action incorrect");
            }
            
            String replyTo = null;
            String repostOf = null;
            boolean tagsFound = false;
            boolean locationFound = false;
            for (BasicNameValuePair p : params)
            {
                if (p.getName() == "tags")
                {
                    tagsFound = true;
                }
                
                if (p.getName() == "reply_to")
                {
                    replyTo = p.getValue();
                }
                
                if (p.getName() == "repost_of")
                {
                    repostOf = p.getValue();
                }
                
                if (p.getName() == "location")
                {
                    locationFound = true;
                }
            }
            assertTrue(tagsFound);
            
            if (action == "reply")
            {
                Assert.assertNotNull(replyTo);
            }
            
            if (action == "repost")
            {
                Assert.assertNotNull(repostOf);
            }
            
            if (action != "repost")
            {
                Assert.assertNotNull(d);
            }
            else
            {
                Assert.assertNull(d);
            }
            
            assertEquals(locationExpected, locationFound);


            return "{ \"id\": \"500c39455e358e7a66000012\"}".getBytes();
        }
    };

    private SnapshotApi sapi = new PostTestSnapshotApi();
    private final SnapshotApi nullSapi = null;

    private final String testPostIdNoReplies = "5013fcaa5e358e7a6600005d";
    private final String testPostIdReplies = "5013fcaa5e358e7a6600005c";
    private final String testAuthor = "5013fca85e358e7a6700004f";
    private final String testPostIdFavFalse = "5013fcaa5e358e7a6600005b";
    private final String testPostIdFavTrue = "5013fcaa5e358e7a6600005a";

    private final String testPostStringNoReplies = "{\n"
            + "            \"flagged\": 0, \n"
            + "            \"disliked\": 0, \n"
            + "            \"author\": \"5013fca85e358e7a6700004f\", \n"
            + "            \"num_replies\": 0, \n"
            + "            \"tags\": [\n" + "                \"attack\", \n"
            + "                \"sleepy\",\n" + "                \"sleepy2\"\n"
            + "            ], \n" + "            \"num_reposts\": 0, \n"
            + "            \"remote_addr\": \"69.136.226.114\", \n"
            + "            \"created\": \"2012-07-28 14:52:26.027000\", \n"
            + "            \"user_agent\": \"Python-urllib/2.7\", \n"
            + "            \"file\": \"placeholder\", \n"
            + "            \"id\": \"5013fcaa5e358e7a6600005c\", \n"
            + "            \"content-type\": \"image\", \n"
            + "            \"enjoyed\": 1, \n"
            + "            \"viewed\": 0, \n"
            + "            \"location\": \"temp\"\n" + "        }";

    private final String testPostStringWithReplies = "{\n"
            + "            \"flagged\": 0, \n"
            + "            \"disliked\": 0, \n"
            + "            \"author\": \"5013fca85e358e7a6700004f\", \n"
            + "            \"num_replies\": 3, \n"
            + "            \"tags\": [\n" + "                \"attack\", \n"
            + "                \"sleepy\",\n" + "                \"sleepy2\"\n"
            + "            ], \n" + "            \"num_reposts\": 0, \n"
            + "            \"remote_addr\": \"69.136.226.114\", \n"
            + "            \"created\": \"2012-07-28 14:52:26.027000\", \n"
            + "            \"user_agent\": \"Python-urllib/2.7\", \n"
            + "            \"file\": \"placeholder\", \n"
            + "            \"id\": \"5013fcaa5e358e7a6600005c\", \n"
            + "            \"content-type\": \"image\", \n"
            + "            \"enjoyed\": 1, \n"
            + "            \"viewed\": 0, \n"
            + "            \"location\": \"temp\"\n" + "        }";
    
    private final String testPostStringWithFavFalse = "{\n"
        + "            \"flagged\": 0, \n"
        + "            \"disliked\": 0, \n"
        + "            \"author\": \"5013fca85e358e7a6700004f\", \n"
        + "            \"num_replies\": 3, \n"
        + "            \"tags\": [\n" + "                \"attack\", \n"
        + "                \"sleepy\",\n" + "                \"sleepy2\"\n"
        + "            ], \n" + "            \"num_reposts\": 0, \n"
        + "            \"remote_addr\": \"69.136.226.114\", \n"
        + "            \"favorite_of_user\": \"false\", \n"
        + "            \"created\": \"2012-07-28 14:52:26.027000\", \n"
        + "            \"user_agent\": \"Python-urllib/2.7\", \n"
        + "            \"file\": \"placeholder\", \n"
        + "            \"id\": \"5013fcaa5e358e7a6600005c\", \n"
        + "            \"content-type\": \"image\", \n"
        + "            \"enjoyed\": 1, \n"
        + "            \"viewed\": 0, \n"
        + "            \"location\": \"temp\"\n" + "        }";
    
    private final String testPostStringWithFavTrue = "{\n"
        + "            \"flagged\": 0, \n"
        + "            \"disliked\": 0, \n"
        + "            \"author\": \"5013fca85e358e7a6700004f\", \n"
        + "            \"num_replies\": 3, \n"
        + "            \"tags\": [\n" + "                \"attack\", \n"
        + "                \"sleepy\",\n" + "                \"sleepy2\"\n"
        + "            ], \n" + "            \"num_reposts\": 0, \n"
        + "            \"remote_addr\": \"69.136.226.114\", \n"
        + "            \"favorite_of_user\": \"true\", \n"
        + "            \"created\": \"2012-07-28 14:52:26.027000\", \n"
        + "            \"user_agent\": \"Python-urllib/2.7\", \n"
        + "            \"file\": \"placeholder\", \n"
        + "            \"id\": \"5013fcaa5e358e7a6600005c\", \n"
        + "            \"content-type\": \"image\", \n"
        + "            \"enjoyed\": 1, \n"
        + "            \"viewed\": 0, \n"
        + "            \"location\": \"temp\"\n" + "        }";

    protected void setUp() throws Exception
    {
        super.setUp();
        locationExpected = false;
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }

    public final void testPostSnapshotApiString()
    {
        try
        {
            new Post(sapi, testPostIdReplies);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("New post creation failed with valid inputs.");
        }

        try
        {
            new Post(sapi, (String) null);
            Assert.fail("New post creation succeeded with invalid inputs. (API, No String)");
        }
        catch (SnapshotApiException e)
        {

        }

        try
        {
            new Post(nullSapi, testPostIdReplies);
            Assert.fail("New post creation succeeded with invalid inputs. (No API, String)");
        }
        catch (SnapshotApiException e)
        {

        }

    }

    public final void testPostSnapshotApiJSONObject() throws JSONException
    {
        JSONObject testObject = new JSONObject(testPostStringWithReplies);
        try
        {
            new Post(sapi, testObject);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("New post creation failed with valid inputs.");
        }

        try
        {
            new Post(sapi, (JSONObject) null);
            Assert.fail("New post creation succeeded with invalid inputs. (API, No JSONObject)");
        }
        catch (SnapshotApiException e)
        {

        }

        try
        {
            new Post(nullSapi, testObject);
            Assert.fail("New post creation succeeded with invalid inputs. (No API, JSONObject)");
        }
        catch (SnapshotApiException e)
        {

        }
    }

    public final void testPostSnapshotApiArrayListOfStringStringString()
    {
        ArrayList<String> tags = new ArrayList<String>();
        tags.add("supb");
        try
        {
            locationExpected = true;
            Post p = new Post(sapi, tags, testPostIdReplies, "here");
            p.addContent(sapi.getBytes(SnapshotApi.SERVICE_SNAPSHOT, null, null));
            p.submit();
        }
        catch (SnapshotApiException e)
        {
            Assert.fail();
        }
        
    }

    public final void testExtractFields() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdReplies);
        Assert.assertEquals(testPostIdReplies, p.getPostId());
        Assert.assertEquals(testAuthor, p.getAuthor());
        Assert.assertTrue(p.hasReplies());
        ArrayList<String> tags = p.getTags();
        Assert.assertEquals("attack", tags.get(0));
        Assert.assertEquals("sleepy", tags.get(1));
        Assert.assertEquals("sleepy2", tags.get(2));

        p = new Post(sapi, testPostIdNoReplies);
        Assert.assertFalse(p.hasReplies());

    }

    public final void testSubmitCreate() throws SnapshotApiException, JSONException
    {
        ArrayList<String> tags = new ArrayList<String>();
        tags.add("1");
        JSONObject newPostId = null;
        Post p = new Post(new PostTestSnapshotApi(), tags, null, null);
        
        newPostId = p.submit();
        assertNotNull(newPostId);
        assertEquals("500c39455e358e7a66000012", newPostId.getString("id"));
    }
    
    public final void testSubmitRepost() throws SnapshotApiException, JSONException
    {
        ArrayList<String> tags = new ArrayList<String>();
        tags.add("1");
        JSONObject newPostId = null;
        Post p = new Post(new PostTestSnapshotApi(), tags, null, null, "123");
        
        newPostId = p.submit();
        assertNotNull(newPostId);
        assertEquals("500c39455e358e7a66000012", newPostId.getString("id"));
    }
    
    public final void testSubmitLocationNotAddedWhenNull() throws SnapshotApiException, JSONException
    {
        ArrayList<String> tags = new ArrayList<String>();
        tags.add("1");
        JSONObject newPostId = null;
        Post p = new Post(new PostTestSnapshotApi(), tags, null, null, "123");
        
        newPostId = p.submit();
        assertNotNull(newPostId);
        assertEquals("500c39455e358e7a66000012", newPostId.getString("id"));
    }
    
    public final void testSubmitLocationAdded() throws SnapshotApiException, JSONException
    {
        ArrayList<String> tags = new ArrayList<String>();
        tags.add("1");
        JSONObject newPostId = null;
        locationExpected = true;
        Post p = new Post(new PostTestSnapshotApi(), tags, null, "1, 2", "123");
        
        newPostId = p.submit();
        assertNotNull(newPostId);
        assertEquals("500c39455e358e7a66000012", newPostId.getString("id"));
    }

    public final void testCleanup() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdReplies);
        p.cleanup();
        Assert.assertFalse(p.isCached());
    }

    public final void testCache() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdReplies);
        p.cache();
        Assert.assertTrue(p.isCached());
    }
    
    public final void testIsFavoritedFalse() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdFavFalse);
        assertFalse(p.isFavorited());
    }
    
    
    public final void testIsFavoritedTrue() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdFavTrue);
        assertTrue(p.isFavorited());
    }
    
    public final void testIsFavoritedTrueThenUnfavorite() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdFavTrue);
        assertTrue(p.isFavorited());
        p.unfavorite();
        assertFalse(p.isFavorited());
    }
    
    public final void testIsFavoritedFalseThenFavorite() throws SnapshotApiException
    {
        Post p = new Post(sapi, testPostIdFavFalse);
        assertFalse(p.isFavorited());
        p.favorite();
        assertTrue(p.isFavorited());
    }
}
