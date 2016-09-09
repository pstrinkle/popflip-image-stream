package com.hyperionstorm.snapshot.api;

import java.util.ArrayList;
import java.util.HashMap;

import org.apache.http.message.BasicNameValuePair;
import junit.framework.TestCase;

public class WatchListTest extends TestCase
{

    private static final String TEST_USER_1 = "1";
    private static final String TEST_USER_2 = "2";

    protected void setUp() throws Exception
    {
        super.setUp();
        MockWatchlistServer.reset();
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
    }
    
    public static class MockWatchlistServer
    {
        public static ArrayList<String> watches = null;
        
        public static void add(String id)
        {
            watches.add(id);
        }
        
        public static void remove(String id)
        {
            for (int i = 0; i < watches.size(); i++)
            {
                if (watches.get(i).equals(id))
                {
                    watches.remove(i);
                }
            }
        }
        
        public static byte[] get()
        {
            String output = "[";
            for (String id : watches)
            {
                output += "\"" + id + "\",";
            }
            if (output.endsWith(","))
            {
                output = output.substring(0, output.length() - 1);
            }
            output += "]";
            return output.getBytes();
        }
        
        public static void reset()
        {
            watches = new ArrayList<String>();
        }
    }
    
    public static void testUserCanAddAUserToWatchList()
    {
        class TestSnapshotApi extends SnapshotApi
        {
            @Override
            public byte[] post(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params,
                HashMap<String, byte[]> multipart)
            {
                assertNull(multipart);
                assertEquals(SnapshotApi.SERVICE_USER, service);
                assertEquals(UserApi.ACTION_WATCH, action);
                
                boolean code = false;
                boolean author = false;
                boolean watched = false;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("code") && p.getValue().equals("98098098098"))
                    {
                        code = true;
                    }
                    if (p.getName().equals("author") && p.getValue().equals(TEST_USER_1))
                    {
                        author = true;
                    }
                    if (p.getName().equals("watched") && p.getValue().equals(TEST_USER_2))
                    {
                        watched = true;
                    }
                }
                
                assertTrue(code && author && watched);
                
                return null;
            }
        }
        class TestCreator implements SnapshotApi.SnapshotApiCreator 
        {
            public SnapshotApi create()
            {
                return new TestSnapshotApi();
            }
        }
        
        WatchList w = new WatchList(TEST_USER_1);
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());
        assertTrue(w.addWatch(TEST_USER_2));
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }
    
    public static void testUserCanBeFoundInWatchList()
    {
        class TestSnapshotApi extends SnapshotApi
        {
            
            @Override
            public byte[] post(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params,
                HashMap<String, byte[]> multipart)
            {
                assertNull(multipart);
                assertEquals(SnapshotApi.SERVICE_USER, service);
                assertEquals(UserApi.ACTION_WATCH, action);
                
                boolean code = false;
                boolean author = false;
                boolean watched = false;
                String candidate = null;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("code") && p.getValue().equals("98098098098"))
                    {
                        code = true;
                    }
                    if (p.getName().equals("author") && p.getValue().equals(TEST_USER_1))
                    {
                        author = true;
                    }
                    if (p.getName().equals("watched") && p.getValue().equals(TEST_USER_2))
                    {
                        watched = true;
                        candidate = p.getValue();
                    }
                }
                
                assertTrue(code && author && watched);
                
                MockWatchlistServer.add(candidate);
                
                return null;
            }
            
            @Override
            public byte[] getBytes(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params)
            {
                if (action.equals("query"))
                {
                    return MockWatchlistServer.get();
                }
                return new byte[0];
            }
        }
        class TestCreator implements SnapshotApi.SnapshotApiCreator 
        {
            public SnapshotApi create()
            {
                return new TestSnapshotApi();
            }
            
            
        }
        WatchList w = new WatchList(TEST_USER_1);
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());
        assertTrue(w.addWatch(TEST_USER_2));
        
        assertTrue(w.isUserWatching(TEST_USER_2));
        
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }
    
    public static void testUserCantBeFoundInWatchList()
    {
        class TestSnapshotApi extends SnapshotApi
        {
            @Override
            public byte[] post(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params,
                HashMap<String, byte[]> multipart)
            {
                assertNull(multipart);
                assertEquals(SnapshotApi.SERVICE_USER, service);
                assertEquals(UserApi.ACTION_WATCH, action);
                
                boolean code = false;
                boolean author = false;
                boolean watched = false;
                String candidate = null;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("code") && p.getValue().equals("98098098098"))
                    {
                        code = true;
                    }
                    if (p.getName().equals("author") && p.getValue().equals(TEST_USER_1))
                    {
                        author = true;
                    }
                    if (p.getName().equals("watched") && p.getValue().equals(TEST_USER_2))
                    {
                        candidate = p.getValue();
                        watched = true;
                    }
                }
                
                assertTrue(code && author && watched);
                
                MockWatchlistServer.add(candidate);
                
                return null;
            }
        }
        class TestCreator implements SnapshotApi.SnapshotApiCreator 
        {
            public SnapshotApi create()
            {
                return new TestSnapshotApi();
            }
        }
        
        WatchList w = new WatchList(TEST_USER_1);
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());
        assertTrue(w.addWatch(TEST_USER_2));

        assertFalse(w.isUserWatching(TEST_USER_1));
        
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }
    
    public static void testUserCantBeFoundInWatchListAddRemove()
    {
        class TestSnapshotApi extends SnapshotApi
        {
            @Override
            public byte[] post(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params,
                HashMap<String, byte[]> multipart)
            {
                assertNull(multipart);
                assertEquals(SnapshotApi.SERVICE_USER, service);
                
                boolean code = false;
                boolean author = false;
                boolean watched = false;
                String candidate = null;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("code") && p.getValue().equals("98098098098"))
                    {
                        code = true;
                    }
                    if (p.getName().equals("author") && p.getValue().equals(TEST_USER_1))
                    {
                        author = true;
                    }
                    if (p.getName().equals("watched") && p.getValue().equals(TEST_USER_2))
                    {
                        candidate = p.getValue();
                        watched = true;
                    }
                }
                
                assertTrue(code && author && watched);
                
                if (action.equals(UserApi.ACTION_WATCH))
                {
                    MockWatchlistServer.add(candidate);
                }
                else
                {
                    MockWatchlistServer.remove(candidate);
                }
                
                return null;
            }
            
            @Override
            public byte[] getBytes(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params)
            {
                if (action.equals("query"))
                {
                    return MockWatchlistServer.get();
                }
                return new byte[0];
            }
        }
        class TestCreator implements SnapshotApi.SnapshotApiCreator 
        {
            public SnapshotApi create()
            {
                return new TestSnapshotApi();
            }
            
            
        }
        WatchList w = new WatchList(TEST_USER_1);
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());

        assertTrue(w.addWatch(TEST_USER_2));
        assertTrue(w.isUserWatching(TEST_USER_2));
        assertTrue(w.removeWatch(TEST_USER_2));
        assertFalse(w.isUserWatching(TEST_USER_2));
        
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }
    
    public static void testUserCanRemoveAUserFromWatchList()
    {
        class TestSnapshotApi extends SnapshotApi
        {
            @Override
            public byte[] post(
                String service,
                String action,
                ArrayList<BasicNameValuePair> params,
                HashMap<String, byte[]> multipart)
            {
                assertNull(multipart);
                assertEquals(SnapshotApi.SERVICE_USER, service);
                assertEquals(UserApi.ACTION_UNWATCH, action);
                
                boolean code = false;
                boolean author = false;
                boolean watched = false;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("code") && p.getValue().equals("98098098098"))
                    {
                        code = true;
                    }
                    if (p.getName().equals("author") && p.getValue().equals(TEST_USER_1))
                    {
                        author = true;
                    }
                    if (p.getName().equals("watched") && p.getValue().equals(TEST_USER_2))
                    {
                        watched = true;
                    }
                }
                
                assertTrue(code && author && watched);
                
                return null;
            }
        }
        class TestCreator implements SnapshotApi.SnapshotApiCreator 
        {
            public SnapshotApi create()
            {
                return new TestSnapshotApi();
            }
            
            
        }
        WatchList w = new WatchList(TEST_USER_1);
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());
        assertTrue(w.removeWatch(TEST_USER_2));
        
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }

}
