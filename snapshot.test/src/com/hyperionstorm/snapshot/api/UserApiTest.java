package com.hyperionstorm.snapshot.api;

import java.util.ArrayList;
import java.util.HashMap;

import junit.framework.TestCase;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONObject;

import com.hyperionstorm.snapshot.api.UserApi.Community;
import com.hyperionstorm.snapshot.api.UserApi.User;
import com.hyperionstorm.snapshot.api.admin.AdminApi;

public class UserApiTest extends TestCase
{
    public static String DOCTOR_POM_SCREENNAME = "doctorpom";
    public static String USER1_SCREENNAME = "user1";
    public static String TestUserId = null;
    public static UserApi userApi = null;

    protected void setUp() throws Exception
    {
        super.setUp();
        boolean adminInit = AdminApi.init();
        assertTrue(adminInit);

        userApi = UserApi.getInstance();
    }
    
    
    public class UserApiGetUserInfoFails extends UserApi
    {
        @Override
        protected JSONObject getUserInfoByCurrentUser()
        {
            return null;
        }
    }

    protected void tearDown() throws Exception
    {
        super.tearDown();
        UserApi.resetInstance();
        SnapshotApi.clearCreator();
        SnapshotApi.clearInstance();
    }
    
    public static void as(String username)
    {
        boolean userLoggedIn = userApi.loginUser(username);
        assertTrue(userLoggedIn);
    }
    
    public static void asFails(String username)
    {
        boolean userLoggedIn = userApi.loginUser(username);
        assertFalse(userLoggedIn);
    }
    
    public static void testGetCurrentUserIdPriorToLogIn()
    {
        assertNull(userApi.getCurrentUserId());
    }
    
    public static void testGetCurrentUserIdAfterLogin()
    {
        as(USER1_SCREENNAME);
        assertEquals(AdminApi.USER1_USER_ID, userApi.getCurrentUserId());
    }
    
    public static void testLoginUnknownFails()
    {
        asFails("SomeUnknownTestUserName");
    }
    
    public static void testLoginTestUserSucceeds()
    {
        as(DOCTOR_POM_SCREENNAME);
        as(USER1_SCREENNAME);
    }

    public static void testGetUserInfoProvidesDisplayName()
    {
        as(DOCTOR_POM_SCREENNAME);
        User user = userApi.getCurrentUserInfo();
        assertEquals("DoctorPOM", user.getDisplayName());
    }
    
    public static void testUserInfoIsUpdatedViaMultipleLogins()
    {
        as(DOCTOR_POM_SCREENNAME);
        User user = userApi.getCurrentUserInfo();
        assertEquals("DoctorPOM", user.getDisplayName());
        as(USER1_SCREENNAME);
        user = userApi.getCurrentUserInfo();
        assertEquals("user1", user.getDisplayName());
    }
    
    public static void testUserCanLogout()
    {
        as(DOCTOR_POM_SCREENNAME);
        assertTrue(userApi.isLoggedIn());
        assertTrue(userApi.logout());
        assertFalse(userApi.isLoggedIn());
    }
    
    public static void testUserInfoNullWhenLoggedOut()
    {
        as(DOCTOR_POM_SCREENNAME);
        assertTrue(userApi.logout());
        assertNull(userApi.getCurrentUserInfo());
    }
    
    public static void testUserIdIsNullWhenLoggedOut()
    {
        as(DOCTOR_POM_SCREENNAME);
        assertTrue(userApi.logout());
        assertNull(userApi.getCurrentUserId());
    }
    
    public static void testUserInfoOfNotTheUser()
    {
        assertTrue(userApi.logout());
        assertNotNull(AdminApi.USER1_USER_ID);
    }
    
    public void testUserLoginWorksButGetFails()
    {
        UserApi api = new UserApiGetUserInfoFails();
        assertFalse(api.loginUser(DOCTOR_POM_SCREENNAME));
    }
    
    public void testUserLoginWorksButGetFailsCurrentUserClear()
    {
        UserApi api = new UserApiGetUserInfoFails();
        assertFalse(api.loginUser(DOCTOR_POM_SCREENNAME));
        assertNull(api.getCurrentUserInfo());
    }
    
    public static void testUserInfoHasEMailField()
    {
        as(DOCTOR_POM_SCREENNAME);
        User user = userApi.getCurrentUserInfo();
        assertNotNull(user);
        
        String email = user.getEMailAddress();
        assertNotNull(email);
        assertEquals(AdminApi.DOCTORPOM_EMAIL_ADDRESS, email);
    }
    
    public static void testUserHasRealNameField()
    {
        as(DOCTOR_POM_SCREENNAME);
        User user = userApi.getCurrentUserInfo();
        assertNotNull(user);
        
        String realName = user.getRealName();
        assertNotNull(realName);
        assertEquals(AdminApi.DOCTORPOM_REAL_NAME, realName);
    }
    
    public static void testUserHasScreenNameField()
    {
        as(DOCTOR_POM_SCREENNAME);
        User user = userApi.getCurrentUserInfo();
        assertNotNull(user);
        
        String screenName = user.getScreenName();
        assertNotNull(screenName);
        assertEquals(AdminApi.DOCTORPOM_SCREEN_NAME, screenName);
    }
    
    public static void testUserHasWebHomeField()
    {
        as(DOCTOR_POM_SCREENNAME);
        User user = userApi.getCurrentUserInfo();
        assertNotNull(user);
        
        String webHome = user.getWebHome();
        assertNotNull(webHome);
        assertEquals(AdminApi.DOCTORPOM_WEB_HOME, webHome);
    }
    
    
    public void testCanGetUsersWatchList()
    {
        as(DOCTOR_POM_SCREENNAME);
        assertNotNull(userApi.getCurrentUserInfo().getWatchlist());
    }
    
    public void testCanTranslateUserIdToScreenName()
    {
        as(DOCTOR_POM_SCREENNAME);
        User u = userApi.getUserInfo(AdminApi.USER1_USER_ID);
        assertNotNull(u);
        assertEquals(AdminApi.USER1_USER_ID, u.getUserId());
    }
    
    public void testCanGetUsersCommunities()
    {
        as(DOCTOR_POM_SCREENNAME);
        assertNotNull(userApi.getCommunities());
    }
    
    public void testUserCanLeaveCommunity()
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
                assertEquals(UserApi.ACTION_LEAVE, action);
                
                boolean user = false;
                boolean community = false;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("user") && p.getValue().equals(AdminApi.DOCTORPOM_USER_ID))
                    {
                        user = true;
                    }
                    if (p.getName().equals("community") && p.getValue().equals("test,community"))
                    {
                        community = true;
                    }
                }
                
                assertTrue(user && community);
                
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
        Community testCommunity = userApi.new Community("test", "community");
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());
        as(DOCTOR_POM_SCREENNAME);
        assertTrue(userApi.leave(testCommunity));
        
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }
    
    public void testUserCanJoinCommunity()
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
                assertEquals(UserApi.ACTION_JOIN, action);
                
                boolean user = false;
                boolean community = false;
                
                for (BasicNameValuePair p : params)
                {
                    if (p.getName().equals("user") && p.getValue().equals(AdminApi.DOCTORPOM_USER_ID))
                    {
                        user = true;
                    }
                    if (p.getName().equals("community") && p.getValue().equals("test,community"))
                    {
                        community = true;
                    }
                }
                
                assertTrue(user && community);
                
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
        Community testCommunity = userApi.new Community("test", "community");
        SnapshotApi.clearInstance();
        SnapshotApi.setCreator(new TestCreator());
        as(DOCTOR_POM_SCREENNAME);
        assertTrue(userApi.join(testCommunity));
        
        SnapshotApi.clearInstance();
        SnapshotApi.clearCreator();
    }

}
