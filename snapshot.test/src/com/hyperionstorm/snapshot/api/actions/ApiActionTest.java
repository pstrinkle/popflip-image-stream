package com.hyperionstorm.snapshot.api.actions;

import junit.framework.TestCase;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;

public class ApiActionTest extends TestCase
{

    protected void setUp() throws Exception
    {
        super.setUp();
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }

    public final void testApiAction()
    {
        try
        {
            new ApiAction(null);
            fail("No API for ApiAction should fail.");
        }
        catch (SnapshotApiException e)
        {
            
        }
        
        try
        {
            new ApiAction(SnapshotApi.getInstance());
        }
        catch (SnapshotApiException e)
        {
            fail("No API for ApiAction should fail.");
        }
    }
}
