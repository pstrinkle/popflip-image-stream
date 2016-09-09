package com.hyperionstorm.snapshot.api;

import junit.framework.TestCase;

import org.apache.http.client.methods.HttpUriRequest;

public class SnapshotHttpClientTest extends TestCase
{
    public class MockSnapshotHttpClient extends SnapshotHttpClient
    {
        boolean getResponseBytesImplCalled = false;
        boolean getClientImplCalled = false;
        
        @Override
        public byte[] getResponseBytesImpl(HttpUriRequest request)
        {
            getResponseBytesImplCalled = true;
            return null;
        }

        @Override
        SnapshotHttpClient getClientImpl()
        {
            getClientImplCalled = true;
            return this;
        }
    }
    
    MockSnapshotHttpClient mockClient = null;
    
    protected void setUp() throws Exception
    {
        super.setUp();
        mockClient = new MockSnapshotHttpClient();
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
        mockClient = null;
    }

    public final void testSetClient()
    {
        mockClient.setClient(mockClient);
        assertNotNull(mockClient.client);
        assertEquals(mockClient, mockClient.client);
    }

    public final void testResetClient()
    {
        mockClient.resetClient();
        assertNull(mockClient.client);
    }

    public final void testGetClient()
    {
        assertEquals(mockClient, mockClient.getClient());
        assertTrue(mockClient.getClientImplCalled);
    }

    public final void testGetResponseBytes()
    {
        mockClient.getResponseBytes(null);
        assertTrue(mockClient.getResponseBytesImplCalled);
    }

}
