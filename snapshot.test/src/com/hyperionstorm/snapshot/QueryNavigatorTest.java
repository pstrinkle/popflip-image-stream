package com.hyperionstorm.snapshot;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;

import junit.framework.Assert;
import junit.framework.TestCase;

import org.apache.http.message.BasicNameValuePair;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.actions.Post;
import com.hyperionstorm.snapshot.api.actions.Query;
import com.hyperionstorm.snapshot.api.actions.Query.QueryType;


public class QueryNavigatorTest extends TestCase
{
    private class TestSnapshotApi extends SnapshotApi
    {
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
        
        @Override
        public byte[] getBytes(String service, String cmd, ArrayList<BasicNameValuePair> params)
        {
            if (cmd.equals(SnapshotApi.ACTION_QUERY))
            {
                return testQuery.getBytes();
            }
            else if (cmd.equals(SnapshotApi.ACTION_VIEW))
            {
                /* send output */
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                Bitmap b = Bitmap.createBitmap(500, 500, Bitmap.Config.ARGB_8888);
                b.compress(CompressFormat.PNG, 100, baos);
                byte[] data = baos.toByteArray();
                return data;
            }
            else
            {
                /* home */
                Assert.assertEquals(SnapshotApi.ACTION_HOME, cmd);
                return testQuery.getBytes();
            }
        }
        
    }
    
    public class TestQueryManager extends QueryManager
    {
        public TestQueryManager() throws SnapshotApiException
        {

        }
    }
    
    public class TestQueryManagerWithNullReturn extends QueryManager
    {
        public TestQueryManagerWithNullReturn()
        {
            
        }
        
        @Override
        public Query getCurrentQuery()
        {
            return null;
        }
    }
    
    public QueryManager tqm = null;
    public QueryNavigator qn = null;
    
    protected void setUp() throws Exception
    {
        super.setUp();
    }
    
    protected void loadTestQuery() throws SnapshotApiException
    {
        tqm = new TestQueryManager();
        tqm.setApi(new TestSnapshotApi());
        tqm.setQueryType(QueryType.QUERY_TYPE_NORM);
        tqm.execute();
        qn = new QueryNavigator(tqm);
    }
    
    protected void loadTestQueryManagerWithoutExec() throws SnapshotApiException
    {
        tqm = new TestQueryManager();
        tqm.setApi(new TestSnapshotApi());
        tqm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qn = new QueryNavigator(tqm);
    }
    
    protected void loadTestQueryManagerNullReturn() throws SnapshotApiException
    {
        tqm = new TestQueryManagerWithNullReturn();
        tqm.setApi(new TestSnapshotApi());
        tqm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qn = new QueryNavigator(tqm);
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }

    public final void testGetCurrentPost() throws SnapshotApiException
    {
        loadTestQuery();
        Post p = qn.getCurrentPost();
        Assert.assertNotNull(p);
        Assert.assertEquals(p.getAuthor(), "5013fca85e358e7a6700004f");
    }
    
    public final void testGetCurrentPostDoesntExceptWithNoQuery() throws SnapshotApiException
    {
        loadTestQueryManagerWithoutExec();
        Post p = qn.getCurrentPost();
        Assert.assertNull(p);
    }

    public final void testGetNextPost() throws SnapshotApiException
    {
        loadTestQuery();
        Post p = qn.getNextPost();
        Assert.assertNotNull(p);
        Assert.assertEquals(p.getAuthor(), "5013fca95e358e7a67000051");
    }

    public final void testGetPrevPost() throws SnapshotApiException
    {
        loadTestQuery();
        /* first check if we can go backwards (to the newest post) from index 0 */
        Post p = qn.getPrevPost();
        Assert.assertNotNull(p);
        Assert.assertEquals(p.getAuthor(), "5013fca85e358e7a6700004f");
        /* advance the post */
        p = qn.getNextPost();
        Assert.assertNotNull(p);
        Assert.assertEquals(p.getAuthor(), "5013fca95e358e7a67000051");
        /* and we should be able to go back */
        p = qn.getPrevPost();
        Assert.assertNotNull(p);
        Assert.assertEquals(p.getAuthor(), "5013fca85e358e7a6700004f");
    }
    
    public final void testCache() throws InterruptedException, SnapshotApiException
    {
        loadTestQuery();
        /* wait for the caching to complete */
        qn.getCurrentPost();
        Thread.currentThread();
        Thread.sleep(5000);
        Query q = tqm.getCurrentQuery();
        Post p = q.getPost(0);
        Assert.assertTrue(p.isCached());
        qn.getNextPost();
        qn.getNextPost();
        qn.getNextPost();
        qn.getNextPost();
        qn.getNextPost();
        qn.getNextPost();
        p = q.getPost(0);
        Thread.currentThread();
        Thread.sleep(5000);
        Assert.assertFalse(p.isCached());
        qn.getPrevPost();
        qn.getPrevPost();
        qn.getPrevPost();
        qn.getPrevPost();
        qn.getPrevPost();
        qn.getPrevPost();
        p = q.getPost(4);
        Thread.currentThread();
        Thread.sleep(5000);
        Assert.assertFalse(p.isCached());
    }
    
    public final void testGetCurrentPostIndex() throws SnapshotApiException
    {
        loadTestQuery();
        qn.currentPostIndex = 1;
        assertEquals(1, qn.getCurrentPostIndex());
    }
    
    public final void testSetCurrentPostIndex() throws SnapshotApiException
    {
        loadTestQuery();
        qn.setCurrentPostIndex(1);
        assertEquals(1, qn.currentPostIndex);
    }

    public final void testSetCurrentPostIndexBounds() throws SnapshotApiException
    {
        loadTestQuery();
        try
        {
            qn.setCurrentPostIndex(-1);
            fail();
        }
        catch (IndexOutOfBoundsException e)
        {
            /* pass negative bound */
        }
        
        try
        {
            qn.setCurrentPostIndex(100);
            fail();
        }
        catch (IndexOutOfBoundsException e)
        {
            /* pass positive bound */
        }
    }
    
    public final void testSetCurrentPostIndexNoQuery() throws SnapshotApiException
    {
        loadTestQueryManagerNullReturn();
        try
        {
            qn.setCurrentPostIndex(1);
            fail();
        }
        catch (IllegalStateException e)
        {
            /* pass */
        }
    }
    
}
