package com.hyperionstorm.snapshot.api;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.mime.HttpMultipartMode;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.ByteArrayBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;

import com.hyperionstorm.snapshot.Log;
import com.hyperionstorm.snapshot.Snapshot;
import com.hyperionstorm.snapshot.SnapshotGui;

public class HttpLib extends SnapshotHttpClient
{
    protected static SnapshotHttpClient thisInstance = null;
    
    protected HttpLib()
    {
        super();
    }
    
    private static SnapshotHttpClient getInstance()
    {
        if (thisInstance == null)
        {
            thisInstance = new HttpLib();
        }
        return thisInstance;
    }
    
    public static final void resetInstance()
    {
        thisInstance = null;
    }
    
    private static final String SnapshotsServiceUri = "http://api.hyperionstorm.com/";
    
    public static final String makePostRequestUrl(String service, String action)
    {
        String httpRequest = SnapshotsServiceUri;
        
        if (service != null)
        {
            httpRequest += URLEncoder.encode(service) + "/";
        }
        
        if (action != null)
        {
            httpRequest += URLEncoder.encode(action);
        }

        return httpRequest;
    }
    
    public static final String makeGetRequestUrl(
            String service,
            String action,
            ArrayList<BasicNameValuePair> values)
    {
        String httpRequest = SnapshotsServiceUri;
        
        if (service != null)
        {
            httpRequest += URLEncoder.encode(service) + "/";
        }
        
        if (action != null)
        {
            httpRequest += URLEncoder.encode(action) + "?";
        }

        httpRequest += urlEncodeParamList(values);
        return httpRequest;
    }
    
    private static final String urlEncodeParamList (
        ArrayList<BasicNameValuePair> params)
    {
        StringBuffer outputBuffer = new StringBuffer(200);
        
        for (BasicNameValuePair pair : params)
        {
            String name = pair.getName();
            String value = pair.getValue();
            if (name == null)
            {
                /* invalid parameter */
                continue;
            }
            if (value == null)
            {
                value = "";
            }
            
            name = URLEncoder.encode(name);
            value = URLEncoder.encode(value);
            
            outputBuffer.append(name);
            outputBuffer.append("=");
            outputBuffer.append(value);
            outputBuffer.append("&");
        }
        
        outputBuffer.trimToSize();
        return outputBuffer.toString();
    }
    
    
    private static final byte[] inputStreamToByteArray(InputStream is) throws IOException
    {
        int nRead;
        byte[] data = new byte[262144];
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        while ((nRead = is.read(data, 0, data.length)) != -1)
        {
            buffer.write(data, 0, nRead);
        }
        buffer.flush();
        return buffer.toByteArray();
    }
    
    public static final byte[] get(String uri)
    {
        if(Snapshot.DEBUG){
            Log.i("Http get: " + uri);
        }
        HttpGet httpget = new HttpGet(uri);
        byte[] response = getInstance().getResponseBytes(httpget);
        return response;
    }
    
    public static final byte[] post(
        String uri,
        ArrayList<BasicNameValuePair> basicParams)
    {
        if(Snapshot.DEBUG){
            Log.i("Http post: " + uri);
        }
        
        UrlEncodedFormEntity urlEncFormEntity = null;
        try
        {
            urlEncFormEntity = new UrlEncodedFormEntity(basicParams);
        }
        catch (Exception e)
        {
            /* any execption here is an input validity/formatting issue */
            e.printStackTrace();
            return null;
        }
        
        HttpPost httpPost = new HttpPost(uri);
        httpPost.setEntity(urlEncFormEntity);
        
        /* execute the POST */
        byte[] response = getInstance().getResponseBytes(httpPost);
        
        return response;
    }
    
    public static final byte[] postMultipart(
        String uri,
        ArrayList<BasicNameValuePair> basicParams,
        HashMap<String, byte[]> multipart)
    {
        if(Snapshot.DEBUG){
            Log.i("Http post: " + uri);
        }
        
        byte[] result = null;
        if(multipart != null)
        {
            if (!multipart.isEmpty())
            {
                MultipartEntity entity = 
                    new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE);
                
                /* add the text parts of the POST */
                for (BasicNameValuePair p : basicParams)
                {
                    try
                    {
                        entity.addPart(p.getName(), new StringBody(p.getValue()));
                    }
                    catch (UnsupportedEncodingException e)
                    {
                        e.printStackTrace();
                        return null;
                    }
                }

                /* add the binary parts of the POST */
                for(String key : multipart.keySet())
                {
                    entity.addPart(key, new ByteArrayBody((byte[]) multipart.get(key), key));
                }
                
                /* generate the request */
                HttpPost httpPost = new HttpPost(uri);
                httpPost.setEntity(entity);
                
                result = getInstance().getResponseBytes(httpPost);
            }
        }
        return result;
    }

    @Override
    byte[] getResponseBytesImpl(HttpUriRequest request)
    {
        HttpClient client = new DefaultHttpClient();
        HttpResponse response = null;
        InputStream is = null;
        byte[] returnArray = null;
        
        try
        {
            response = client.execute(request);
            is = response.getEntity().getContent();
            
            returnArray = inputStreamToByteArray(is);
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
        catch (RuntimeException e)
        {
            e.printStackTrace();
            request.abort();
        }
        finally
        {
            if(is != null)
            {
                try
                {
                    is.close();
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
            }
        }
        
        return returnArray;
    }

    @Override
    SnapshotHttpClient getClientImpl()
    {
        return this;
    }

}
