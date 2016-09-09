package com.hyperionstorm.snapshot.api.actions;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;

public class ApiAction extends Object
{
    protected SnapshotApi api = null;
    
    public ApiAction(SnapshotApi sapi) throws SnapshotApiException
    {
        super();
        
        api = sapi;
        
        if (api == null)
        {
            NullPointerException e = new NullPointerException("API is null");
            throw new SnapshotApiException(e);
        }
    }
    
}
