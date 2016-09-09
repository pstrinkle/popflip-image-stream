package com.hyperionstorm.snapshot.api.actions;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;

import junit.framework.Assert;
import junit.framework.TestCase;

import org.apache.http.message.BasicNameValuePair;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.actions.Query.QueryType;
import com.hyperionstorm.snapshot.api.admin.AdminApi;

public class QueryTest extends TestCase
{
    private class PostTestSnapshotApi extends SnapshotApi
    {
        @Override
        public byte[] getBytes(String service, String cmd, ArrayList<BasicNameValuePair> params)
        {
            if (cmd.equals(SnapshotApi.ACTION_QUERY))
            {
                String tag = null;
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("tag"))
                    {
                        tag = p.getValue();
                        break;
                    }
                }
                if (tag != null)
                {
                    return testQuery.getBytes();
                }
                else
                {
                    return "[]".getBytes();
                }
            }
            else if (cmd.equals(SnapshotApi.ACTION_VIEW))
            {
                /* send output */
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                Bitmap b = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888);
                b.compress(CompressFormat.PNG, 100, baos);
                byte[] data = baos.toByteArray();
                return data;
            }
            else if (cmd.equals(SnapshotApi.ACTION_HOME))
            {
                return testQuery.getBytes();
            }
            else if (cmd.equals(SnapshotApi.ACTION_PUBLIC))
            {
                Assert.assertEquals(SnapshotApi.ACTION_PUBLIC, cmd);
                return testQuery.getBytes();
            }
            else
            {
                fail("unexpected action");
                return null;
            }
        }
    };
    
    private final String testQuery = "[\n" + 
    		"    {\n" + 
    		"        \"flagged\": 0, \n" + 
    		"        \"disliked\": 0, \n" + 
    		"        \"author\": \"5013fca85e358e7a6700004f\", \n" + 
    		"        \"num_replies\": 0, \n" + 
    		"        \"tags\": [\n" + 
    		"            \"jack\", \n" + 
    		"            \"eskimo\", \n" + 
    		"            \"attack\"\n" + 
    		"        ], \n" + 
    		"        \"num_reposts\": 0, \n" + 
    		"        \"remote_addr\": \"69.136.226.114\", \n" + 
    		"        \"created\": \"2012-07-28 14:52:33.096000\", \n" + 
    		"        \"user_agent\": \"Python-urllib/2.7\", \n" + 
    		"        \"file\": \"placeholder\", \n" + 
    		"        \"id\": \"5013fcb15e358e7a6600005f\", \n" + 
    		"        \"content-type\": \"image\", \n" + 
    		"        \"enjoyed\": 1, \n" + 
    		"        \"viewed\": 0, \n" + 
    		"        \"location\": \"temp\"\n" + 
    		"    }, \n" + 
    		"    {\n" + 
    		"        \"flagged\": 0, \n" + 
    		"        \"disliked\": 0, \n" + 
    		"        \"author\": \"5013fca95e358e7a67000051\", \n" + 
    		"        \"num_replies\": 0, \n" + 
    		"        \"tags\": [\n" + 
    		"            \"jack\"\n" + 
    		"        ], \n" + 
    		"        \"num_reposts\": 0, \n" + 
    		"        \"remote_addr\": \"69.136.226.114\", \n" + 
    		"        \"created\": \"2012-07-28 14:53:00.075000\", \n" + 
    		"        \"user_agent\": \"Python-urllib/2.7\", \n" + 
    		"        \"file\": \"placeholder\", \n" + 
    		"        \"id\": \"5013fccc5e358e7a66000062\", \n" + 
    		"        \"content-type\": \"image\", \n" + 
    		"        \"enjoyed\": 0, \n" + 
    		"        \"viewed\": 0, \n" + 
    		"        \"location\": \"temp\"\n" + 
    		"    }, \n" + 
    		"    {\n" + 
    		"        \"flagged\": 0, \n" + 
    		"        \"disliked\": 0, \n" + 
    		"        \"author\": \"5013fca95e358e7a66000037\", \n" + 
    		"        \"num_replies\": 1, \n" + 
    		"        \"tags\": [\n" + 
    		"            \"attack\", \n" + 
    		"            \"sleepy\", \n" + 
    		"            \"jack\"\n" + 
    		"        ], \n" + 
    		"        \"num_reposts\": 1, \n" + 
    		"        \"remote_addr\": \"69.136.226.114\", \n" + 
    		"        \"created\": \"2012-07-28 14:53:01.249000\", \n" + 
    		"        \"user_agent\": \"Python-urllib/2.7\", \n" + 
    		"        \"file\": \"placeholder\", \n" + 
    		"        \"id\": \"5013fccd5e358e7a67000061\", \n" + 
    		"        \"content-type\": \"image\", \n" + 
    		"        \"enjoyed\": 0, \n" + 
    		"        \"viewed\": 0, \n" + 
    		"        \"location\": \"temp\"\n" + 
    		"    }, \n" + 
    		"    {\n" + 
    		"        \"flagged\": 0, \n" + 
    		"        \"disliked\": 0, \n" + 
    		"        \"author\": \"5013fca85e358e7a66000033\", \n" + 
    		"        \"num_replies\": 0, \n" + 
    		"        \"tags\": [\n" + 
    		"            \"jack\", \n" + 
    		"            \"couch\"\n" + 
    		"        ], \n" + 
    		"        \"num_reposts\": 0, \n" + 
    		"        \"remote_addr\": \"69.136.226.114\", \n" + 
    		"        \"created\": \"2012-07-28 14:53:03.835000\", \n" + 
    		"        \"user_agent\": \"Python-urllib/2.7\", \n" + 
    		"        \"file\": \"placeholder\", \n" + 
    		"        \"id\": \"5013fcd05e358e7a67000062\", \n" + 
    		"        \"content-type\": \"image\", \n" + 
    		"        \"enjoyed\": 0, \n" + 
    		"        \"viewed\": 0, \n" + 
    		"        \"location\": \"temp\"\n" + 
    		"    }, \n" + 
    		"    {\n" + 
    		"        \"flagged\": 0, \n" + 
    		"        \"disliked\": 0, \n" + 
    		"        \"num_replies\": 0, \n" + 
    		"        \"tags\": [\n" + 
    		"            \"jack\", \n" + 
    		"            \"jack\"\n" + 
    		"        ], \n" + 
    		"        \"num_reposts\": 0, \n" + 
    		"        \"author\": \"5013fca85e358e7a66000033\", \n" + 
    		"        \"location\": \"temp\", \n" + 
    		"        \"created\": \"2012-07-28 14:53:16.615000\", \n" + 
    		"        \"id\": \"5013fcdc5e358e7a67000063\", \n" + 
    		"        \"remote_addr\": \"69.136.226.114\", \n" + 
    		"        \"file\": \"placeholder\", \n" + 
    		"        \"reply_to\": \"5013fcd35e358e7a66000065\", \n" + 
    		"        \"content-type\": \"image\", \n" + 
    		"        \"enjoyed\": 0, \n" + 
    		"        \"viewed\": 0, \n" + 
    		"        \"user_agent\": \"Python-urllib/2.7\"\n" + 
    		"    }\n" + 
    		"]";
    
    protected void setUp() throws Exception
    {
        super.setUp();
        AdminApi.init();
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }
    
    public void testSourceFactors()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        factors.add(new BasicNameValuePair("tag", "sometag"));
        factors.add(new BasicNameValuePair("foo", "bar"));
        factors.add(new BasicNameValuePair("fubar", "fubar"));
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_NORM);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
        
        ArrayList<BasicNameValuePair> sourceFactors = q.getSourceFactors();
        assertEquals(factors, sourceFactors);
    }
    
    public void testCount()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        factors.add(new BasicNameValuePair("tag", "sometag"));
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_NORM);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
        
        Assert.assertEquals(5, q.count());
    }
    
    public void testGetPost()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        factors.add(new BasicNameValuePair("tag", "sometag"));
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_NORM);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
        for (int i = 0; i < 5; i++)
        {
            Assert.assertNotNull(q.getPost(i));
        }
        
        Assert.assertNull(q.getPost(5));
    }
    
    public void testCleanup()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        factors.add(new BasicNameValuePair("tag", "sometag"));
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_NORM);
        }
        catch (SnapshotApiException e)
        {
            fail("Query creation failed with valid parameters.");
        }
        
        for (int i = 0; i < 5; i++)
        {
            q.getPost(i).cache();
            Assert.assertTrue(q.getPost(i).isCached());
        }
        q.cleanup();
        for (int i = 0; i < 5; i++)
        {
            Assert.assertFalse(q.getPost(i).isCached());
        }
    }

    public void testEmptySet()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_NORM);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
        
        Assert.assertEquals(0, q.count());
    }
    
    public void testHome()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_HOME);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
        Assert.assertEquals(5, q.count());
    }
    
    public void testHomeWithUser()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        factors.add(new BasicNameValuePair("user", AdminApi.DOCTORPOM_USER_ID));
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_HOME);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
        Assert.assertEquals(5, q.count());
    }
    
    public void testPublic()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_PUBLIC);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
    }
    
    public void testPublicWithUser()
    {
        ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
        factors.add(new BasicNameValuePair("user", AdminApi.DOCTORPOM_USER_ID));
        Query q = null;
        try
        {
            q = new Query(new PostTestSnapshotApi(), factors, QueryType.QUERY_TYPE_PUBLIC);
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Query creation failed with valid parameters.");
        }
    }
}
