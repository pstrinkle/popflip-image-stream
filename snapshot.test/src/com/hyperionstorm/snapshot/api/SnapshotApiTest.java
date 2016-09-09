package com.hyperionstorm.snapshot.api;
import java.util.ArrayList;
import java.util.HashMap;

import junit.framework.TestCase;

import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;


public class SnapshotApiTest extends TestCase
{
    class TestSnapshotApiCreator
    implements SnapshotApi.SnapshotApiCreator
    {
        public SnapshotApi create()
        {
            return new MockSnapshotApi();
        }
    }

    class MockSnapshotApi 
        extends SnapshotApi 
    {
    
    }

    public HttpUriRequest lastRequest = null;

    public class MockHttpLib extends HttpLib
    {
        @Override
        public SnapshotHttpClient getClientImpl()
        {
            return this;
        }
        
        
        @Override
        public byte[] getResponseBytesImpl(HttpUriRequest request)
        {
            lastRequest  = request;
            return resultArray;
        }
    }
    
    public MockHttpLib mockHttpLib = new MockHttpLib();
    public static final byte[] resultArray = "{ foo : \"bar\" }".getBytes();
    
    protected void setUp() throws Exception
    {
        super.setUp();
        MockHttpLib.thisInstance = mockHttpLib;
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
        mockHttpLib.resetClient();
        HttpLib.resetInstance();
        SnapshotApi.clearCreator();
        SnapshotApi.clearInstance();
    }

    public final void testGetInstance()
    {
        SnapshotApi testInstance = SnapshotApi.getInstance();
        assertNotNull(testInstance);
    }
    
    public final void testSetCreator()
    {
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestSnapshotApiCreator());
        SnapshotApi testInstance = SnapshotApi.getInstance();
        assertTrue(testInstance instanceof MockSnapshotApi);
    }

    public final void testPost()
    {
        SnapshotApi testInstance = SnapshotApi.getInstance();
        byte[] result = null;
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        
        result = testInstance.post(SnapshotApi.SERVICE_SNAPSHOT, SnapshotApi.ACTION_QUERY, values, null);
        assertEquals(resultArray, result);
        HttpPost post = (HttpPost) lastRequest;
        assertTrue(post.getEntity() instanceof UrlEncodedFormEntity);
    }

    public final void testPostWithMultipart()
    {
        SnapshotApi testInstance = SnapshotApi.getInstance();
        byte[] result = null;
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        HashMap<String, byte[]> multipart = new HashMap<String, byte[]>();
        multipart.put("data", new byte[] {0, 1});
        
        result = testInstance.post(SnapshotApi.SERVICE_SNAPSHOT, SnapshotApi.ACTION_QUERY, values, multipart);
        assertEquals(resultArray, result);
        HttpPost post = (HttpPost) lastRequest;
        assertTrue(post.getEntity() instanceof MultipartEntity);
    }

    public final void testGetJsonObject()
    {
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        SnapshotApi testInstance = SnapshotApi.getInstance();
        try
        {
            JSONObject result = testInstance.getJsonObject(SnapshotApi.SERVICE_SNAPSHOT, SnapshotApi.ACTION_QUERY, values);
            assertEquals("bar", result.getString("foo"));
        }
        catch (SnapshotApiException e)
        {
            e.printStackTrace();
            fail("safe getJsonObject failed");
        }
        catch (JSONException e)
        {
            e.printStackTrace();
            fail("safe getJsonObject had missing field");
        }
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=bar&",
            lastRequest.getURI().toASCIIString());
    }

    public final void testGetBytes()
    {
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        SnapshotApi testInstance = SnapshotApi.getInstance();
        byte[] result = testInstance.getBytes(SnapshotApi.SERVICE_SNAPSHOT, SnapshotApi.ACTION_QUERY, values);
        assertEquals(resultArray, result);
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=bar&",
            lastRequest.getURI().toASCIIString());
    }

}
