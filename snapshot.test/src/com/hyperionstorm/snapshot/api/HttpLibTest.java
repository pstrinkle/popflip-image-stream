package com.hyperionstorm.snapshot.api;

import java.util.ArrayList;
import java.util.HashMap;

import junit.framework.TestCase;

import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.message.BasicNameValuePair;

/* TODO needs to test getResponseBytesImpl */
public class HttpLibTest extends TestCase
{
    /* haha funny but valid variable name */
    public static HttpUriRequest lastRequest = null;
    /* this mock just prevents the test from hitting the web */
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
            lastRequest = request;
            return resultArray;
        }
    }
    
    public static final byte[] resultArray = new byte[] {0, 1, 2, 3};
    public MockHttpLib mockHttpLib = new MockHttpLib();

    protected void setUp() throws Exception
    {
        super.setUp();
        MockHttpLib.thisInstance = mockHttpLib;
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
        mockHttpLib.resetClient();
    }

    public final void testMakeGetRequestUrl()
    {
        String httpGetRequestUrl = null;

        ArrayList<BasicNameValuePair> nulVal = new ArrayList<BasicNameValuePair>();
        nulVal.add(new BasicNameValuePair("foo", null));
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            SnapshotApi.ACTION_QUERY,
            nulVal);
        
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=&",
            httpGetRequestUrl);
        
        ArrayList<BasicNameValuePair> empVal = new ArrayList<BasicNameValuePair>();
        empVal.add(new BasicNameValuePair("foo", ""));
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            SnapshotApi.ACTION_QUERY,
            empVal);
        
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=&",
            httpGetRequestUrl);
        
        ArrayList<BasicNameValuePair> ampVal = new ArrayList<BasicNameValuePair>();
        ampVal.add(new BasicNameValuePair("foo", "&"));
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            SnapshotApi.ACTION_QUERY,
            ampVal);
        
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=%26&",
            httpGetRequestUrl);
        
        ArrayList<BasicNameValuePair> noVals = new ArrayList<BasicNameValuePair>();
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            SnapshotApi.ACTION_QUERY,
            noVals);
        
        assertEquals("http://api.hyperionstorm.com/snapshot/query?",
            httpGetRequestUrl);
        
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        values.add(new BasicNameValuePair("foo", "bar"));
        values.add(new BasicNameValuePair("foo", "bar"));
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            SnapshotApi.ACTION_QUERY,
            values);
        
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=bar&foo=bar&foo=bar&",
            httpGetRequestUrl);
        
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            null,
            SnapshotApi.ACTION_QUERY,
            values);
        assertEquals("http://api.hyperionstorm.com/query?foo=bar&foo=bar&foo=bar&",
            httpGetRequestUrl);
        
        httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            null,
            values);
        assertEquals("http://api.hyperionstorm.com/snapshot/foo=bar&foo=bar&foo=bar&",
            httpGetRequestUrl);
    }
    
    public final void testMakePostRequestUrl()
    {
        String httpPostRequestUrl = HttpLib.makePostRequestUrl("foo","bar");
        assertEquals("http://api.hyperionstorm.com/foo/bar", httpPostRequestUrl);
        
        httpPostRequestUrl = HttpLib.makePostRequestUrl(null, "bar");
        assertEquals("http://api.hyperionstorm.com/bar", httpPostRequestUrl);
        
        httpPostRequestUrl = HttpLib.makePostRequestUrl("foo", null);
        assertEquals("http://api.hyperionstorm.com/foo/", httpPostRequestUrl);
    }
    
    public final void testGet()
    {
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        values.add(new BasicNameValuePair("foo", "bar"));
        values.add(new BasicNameValuePair("foo", "bar"));
        String httpGetRequestUrl = HttpLib.makeGetRequestUrl(
            SnapshotApi.SERVICE_SNAPSHOT,
            SnapshotApi.ACTION_QUERY,
            values);
        
        assertEquals("http://api.hyperionstorm.com/snapshot/query?foo=bar&foo=bar&foo=bar&",
            httpGetRequestUrl);
        
        byte[] result = MockHttpLib.get(httpGetRequestUrl);
        assertEquals(resultArray, result);
    }

    public final void testPost()
    {
        byte[] result = null;
        String postRequestUrl = HttpLib.makePostRequestUrl("foo", "bar");
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        
        result = MockHttpLib.post(postRequestUrl, values);
        /* make sure it was our implementation that was called */
        assertNotNull(lastRequest);
        assertEquals(resultArray, result);
        
        /* make sure we don't accept null parameters */
        result = MockHttpLib.post(postRequestUrl, null);
        assertNull(result);
        
        /* make sure we will submit handle NO parameters */
        ArrayList<BasicNameValuePair> noVals = new ArrayList<BasicNameValuePair>();
        result = MockHttpLib.post(postRequestUrl, noVals);
        assertNotNull(result);
    }
    
    public final void testPostMultipart()
    {
        byte[] result = null;
        HashMap<String, byte[]> multipart = null;
        String postRequestUrl = HttpLib.makePostRequestUrl("foo", "bar");
        ArrayList<BasicNameValuePair> values = new ArrayList<BasicNameValuePair>();
        values.add(new BasicNameValuePair("foo", "bar"));
        
        /* make sure we don't allow empty/null multipart components */
        result = MockHttpLib.postMultipart(postRequestUrl, values, multipart);
        assertNull(result);
        multipart = new HashMap<String, byte[]>();
        result = MockHttpLib.postMultipart(postRequestUrl, values, multipart);
        assertNull(result);
        
        
        /* make sure we add the basic parameters to the multipart stream */
        multipart.put("data", new byte[] {0, 1});
        result = MockHttpLib.postMultipart(postRequestUrl, values, multipart);
        assertNotNull(result);
        HttpPost post = (HttpPost) lastRequest;
        /* verify the multipart piece has been added */
        assertTrue(post.getEntity() instanceof MultipartEntity);
        
        /* the tests below are non-trivial and no implementation has arisen */
        /* TODO pick through the entity then find and verify the basic params */
        /* TODO pick through the entity then find and verify the data params */
    }
}
