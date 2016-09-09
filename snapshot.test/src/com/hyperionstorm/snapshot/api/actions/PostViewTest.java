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

public class PostViewTest extends TestCase
{
    private class PostTestSnapshotApi extends SnapshotApi
    {
        @Override
        public byte[] getBytes(String service, String cmd, ArrayList<BasicNameValuePair> params)
        {
            /* verify input (sent to the server) */
            /*Assert.assertTrue(params.containsKey("id"));
            Assert.assertNotNull(params.get("id"));
            Assert.assertEquals(cmd, "view?");*/
            
            /* send output */
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Bitmap b = Bitmap.createBitmap(500, 500, Bitmap.Config.ARGB_8888);
            b.compress(CompressFormat.PNG, 100, baos);
            byte[] data = baos.toByteArray();
            return data;
        }
    };
    
    private SnapshotApi sapi = new PostTestSnapshotApi();
    private final SnapshotApi nullSapi = null;
    
    protected void setUp() throws Exception
    {
        super.setUp();
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }

    public final void testPostView() throws SnapshotApiException
    {
        new PostView(sapi, "1234");
        try
        {
            new PostView(nullSapi, "1234");
            Assert.fail("PostView loaded from a null API?");
        }
        catch (SnapshotApiException e)
        {
            
        }
        
        try
        {
            new PostView(sapi, null);
            Assert.fail("PostView loaded from a null API?");
        }
        catch (SnapshotApiException e)
        {
            
        }
        
    }

    public final void testGetImage()
    {
        PostView pv = null;
        try
        {
            pv = new PostView(sapi, "1234");
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Valid parameters should not fail.");
        }
        Assert.assertNotNull(pv.getImage());
        Assert.assertTrue(pv.getImage() instanceof Bitmap);
    }
    
    public final void testGetRaw()
    {
        PostView pv = null;
        try
        {
            pv = new PostView(sapi, "1234");
        }
        catch (SnapshotApiException e)
        {
            Assert.fail("Valid parameters should not fail.");
        }
        Assert.assertNotNull(pv.getRaw());
    }

}
