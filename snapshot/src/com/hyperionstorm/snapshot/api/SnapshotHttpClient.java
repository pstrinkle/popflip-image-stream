package com.hyperionstorm.snapshot.api;

import org.apache.http.client.methods.HttpUriRequest;

public abstract class SnapshotHttpClient
{
    abstract SnapshotHttpClient getClientImpl();
    
    abstract byte[] getResponseBytesImpl(HttpUriRequest request);
    
    protected SnapshotHttpClient client = null;
    
    public void setClient(SnapshotHttpClient httpClient)
    {
        client = httpClient;
    }
   
    public void resetClient()
    {
        client = null;
    }
    
    public SnapshotHttpClient getClient()
    {
        if (client == null)
        {
            client = getClientImpl();
        }
        return client;
    }

    public byte[] getResponseBytes(HttpUriRequest request)
    {
        return getClient().getResponseBytesImpl(request);
    }
}
