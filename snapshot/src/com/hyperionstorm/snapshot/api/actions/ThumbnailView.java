package com.hyperionstorm.snapshot.api.actions;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;

public class ThumbnailView extends PostView
{
    public ThumbnailView(SnapshotApi sapi, String postContentId) 
            throws SnapshotApiException
    {   
        super(sapi, postContentId);
    }
    
    @Override
    protected void assignFilename(String id){
        filename = "postview-cache-image-" + id + "-thumbnail.tmp";
    }
    
    @Override
    protected boolean isThumbnail(){
        return true;
    }
}
