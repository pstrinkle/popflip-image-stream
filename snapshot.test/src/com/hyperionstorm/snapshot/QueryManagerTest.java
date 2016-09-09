package com.hyperionstorm.snapshot;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;

import junit.framework.Assert;
import junit.framework.TestCase;

import org.apache.http.message.BasicNameValuePair;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.actions.Query;
import com.hyperionstorm.snapshot.api.actions.Query.QueryType;

public class QueryManagerTest extends TestCase
{
    public boolean apiCalled;

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
            apiCalled = true;
            if (cmd.equals(SnapshotApi.ACTION_QUERY))
            {
                if (!params.isEmpty())
                {
                    return testQuery.getBytes();    
                }
                return "[]".getBytes();
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

    public QueryManager qm = null;
    
    protected void setUp() throws Exception
    {
        super.setUp();
        qm = new QueryManager();
        qm.setApi(new TestSnapshotApi());
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }

    public final void testGetCurrentQuery()
    {
        Assert.assertNull(qm.getCurrentQuery());
        qm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qm.setQueryParam("arm", "abi");
        qm.execute();
        Assert.assertNotNull(qm.getCurrentQuery());
    }

    public final void testSetApi()
    {
        Assert.assertNull(qm.getCurrentQuery());
        qm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qm.setQueryParam("arm", "abi");
        qm.execute();
        Assert.assertNotNull(qm.getCurrentQuery());
        Assert.assertTrue(apiCalled);
    }

    public final void testSetQueryParam()
    {
        qm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qm.setQueryParam("bob", "dole0");
        qm.setQueryParam("bob", "dole1");
        qm.setQueryParam("bob", "dole2");
        qm.setQueryParam("tag", "stringcheese");
        qm.execute();
        qm.getCurrentQuery();
        Query q = qm.getCurrentQuery();
        ArrayList<BasicNameValuePair> sourceFactors = q.getSourceFactors();
        boolean doles = false;
        boolean stringcheese = false;
        for(BasicNameValuePair p : sourceFactors)
        {
            String name = p.getName();
            String value = p.getValue();
            if (name.equals("bob") && value.equals("dole0,dole1,dole2"))
            {
                doles = true;
            }
            if (name.equals("tag") && value.equals("stringcheese"))
            {
                stringcheese = true;
            }
        }
        assertTrue(doles && stringcheese);
    }

    public final void testClearQueryParams()
    {
        Assert.assertNull(qm.getCurrentQuery());
        qm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qm.setQueryParam("arm", "abi");
        qm.clearQueryParams();
        qm.execute();
        Assert.assertNull(qm.getCurrentQuery());
    }

    public final void testExecute()
    {
        Assert.assertNull(qm.getCurrentQuery());
        qm.setQueryType(QueryType.QUERY_TYPE_NORM);
        qm.setQueryParam("arm", "abi");
        qm.execute();
        Assert.assertNotNull(qm.getCurrentQuery());
    }

}
