package com.hyperionstorm.snapshot.api;

import java.util.ArrayList;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class UserApi
{
    public class Community extends Object
    {
        public String tagA;
        public String tagB;
        
        public Community(String a, String b)
        {
            /** @todo maybe sort on contruction? */
            tagA = a;
            tagB = b;
        }
        
        @Override
        public String toString()
        {
            if (tagA == null && tagB == null)
            {
                return null;
            }
            else if (tagA == null && tagB != null)
            {
                return tagB;
            }
            else if (tagA != null && tagB == null)
            {
                return tagA;
            }
            else
            {
                return tagA + "," + tagB;
            }
        }
        
    }
    
    public class User
    {
        private String displayName = null;
        private String userId = null;
        private String emailAddress = null;
        private String realName;
        private String screenName;
        private String webHome;
        private JSONObject originalJSON;
        protected WatchList watchlist = null;
        
        public User(String userId)
        {
            watchlist = new WatchList(userId);
            this.userId = userId;
        }
        
        public String[] getWatchlist()
        {
            return watchlist.watchList.clone();
        }
        
        public boolean addWatch(String userId)
        {
            return watchlist.addWatch(userId);
        }

        public boolean removeWatch(String userId)
        {
            return watchlist.removeWatch(userId);
        }
        
        public boolean isUserWatching(String author)
        {
            return watchlist.isUserWatching(author);
        }

        public String getDisplayName()
        {
            return displayName;
        }

        public void setDisplayName(String displayName)
        {
            this.displayName = displayName;
        }
        
        public String getUserId()
        {
            return this.userId;
        }
        
        public void setEMailAddress(String emailAddress)
        {
            this.emailAddress = emailAddress;
        }

        public String getEMailAddress()
        {
            return this.emailAddress;
        }
        
        public void setRealName(String realName)
        {
            this.realName = realName;
        }

        public String getRealName()
        {
            return this.realName;
        }
        
        public void setScreenName(String screenName)
        {
            this.screenName = screenName;
        }

        public String getScreenName()
        {
            return this.screenName;
        }
        
        public void setWebHome(String webHome)
        {
            this.webHome = webHome;
        }

        public String getWebHome()
        {
            return this.webHome;
        }
        
        public void fillFromJSON(JSONObject userInfo) throws JSONException
        {
            this.originalJSON = userInfo;
            this.setDisplayName(userInfo.getString("display_name"));
            this.setRealName(userInfo.getString("realish_name"));
            this.setScreenName(userInfo.getString("screen_name"));
            this.setWebHome(userInfo.getString("home"));
        }
    }
    
    protected static final String ACTION_LOGIN = "login";
    protected static final String ACTION_GET = "get";
    protected static final String ACTION_WATCH = "watch";
    protected static final String ACTION_UNWATCH = "unwatch";
    protected static final String ACTION_QUERY = "query";
    protected static final String ACTION_LEAVE = "leave";
    protected static final String ACTION_JOIN = "join";
    private static UserApi thisUserApi = null;
    private static User currentUser = null;
    
    protected UserApi()
    {
        super();
        currentUser = null;
    }
    
    public static UserApi getInstance()
    {
        if (thisUserApi == null)
        {
            thisUserApi = new UserApi();
        }
        return thisUserApi;
    }
    
    public static void resetInstance()
    {
        thisUserApi = null;
    }
    
    public boolean loginUser(String username)
    {
        String userId = null;
        JSONObject userIdResult = null;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("screen_name", username));
        
        SnapshotApi api = SnapshotApi.getInstance();
        try
        {
            userIdResult = api.getJsonObject(SnapshotApi.SERVICE_USER, UserApi.ACTION_LOGIN, params);
        }
        catch (SnapshotApiException e)
        {
            e.printStackTrace();
            return false;
        }
        
        try
        {
            userId = userIdResult.getString("id");
        }
        catch (JSONException e)
        {
            e.printStackTrace();
            return false;
        }
        
        currentUser = new User(userId);
        
        if(!updateUserInfo())
        {
            currentUser = null;
            return false;
        }
        
        currentUser.watchlist.cache();
        
        return true;
    }
    
    private boolean updateUserInfo()
    {
        JSONObject userGetResult = getUserInfoByCurrentUser();
        if (userGetResult == null)
        {
            return false;
        }
        
        try
        {
            extractUserInfo(userGetResult, currentUser);
        }
        catch (JSONException e)
        {
            e.printStackTrace();
            return false;
        }
        
        return true;
    }
    
    private void extractUserInfo(JSONObject userInfo, User u) throws JSONException
    {
        u.fillFromJSON(userInfo);
    }
    
    protected JSONObject getUserInfoByCurrentUser()
    {
        JSONObject userGetResult = null;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("id", currentUser.getUserId()));
        
        SnapshotApi api = SnapshotApi.getInstance();
        try
        {
            userGetResult = api.getJsonObject(SnapshotApi.SERVICE_USER, UserApi.ACTION_GET, params);
        }
        catch (SnapshotApiException e)
        {
            e.printStackTrace();
            userGetResult = null;
        }
        
        return userGetResult;
    }
    
    protected JSONObject getUserInfoById(String userId)
    {
        JSONObject userGetResult = null;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("id", userId));
        
        SnapshotApi api = SnapshotApi.getInstance();
        try
        {
            userGetResult = api.getJsonObject(SnapshotApi.SERVICE_USER, UserApi.ACTION_GET, params);
        }
        catch (SnapshotApiException e)
        {
            e.printStackTrace();
            userGetResult = null;
        }
        
        return userGetResult;
    }

    public String getCurrentUserId()
    {
        if (currentUser == null)
        {
            return null;
        }
        return currentUser.getUserId();
    }

    public boolean isLoggedIn()
    {
        if (currentUser == null)
        {
            return false;
        }
        return true;
    }

    public boolean logout()
    {
        currentUser = null;
        return true;
    }

    public User getCurrentUserInfo()
    {
        return currentUser;
    }
    
    public User getUserInfo(String userId)
    {
        User u = new User(userId);
        try
        {
            extractUserInfo(getUserInfoById(userId), u);
        }
        catch (JSONException e)
        {
           return null;
        }
        return u;
    }

    public Community[] getCommunities()
    {
        Community[] communities = new Community[5];
        SnapshotApi api = SnapshotApi.getInstance();
        byte[] results = null;
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("id", getCurrentUserId()));
        params.add(new BasicNameValuePair("query", "community"));
        results = api.getBytes(SnapshotApi.SERVICE_USER, UserApi.ACTION_QUERY, params);
        
        try
        {
            JSONArray comms = new JSONArray(new String(results));
            communities = new Community[comms.length()];
            for (int i = 0; i < comms.length(); i++)
            {
                JSONArray comm = new JSONArray(comms.getString(i));
                communities[i] = new Community(comm.getString(0), comm.getString(1));
            }
        }
        catch (JSONException e)
        {
            return new Community[0];
        }
        
        return communities;
    }

    public boolean leave(Community community)
    {
        SnapshotApi api = SnapshotApi.getInstance();
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("user", getCurrentUserId()));
        params.add(new BasicNameValuePair("community", community.toString()));
        api.post(SnapshotApi.SERVICE_USER, UserApi.ACTION_LEAVE, params, null);
        return true;
    }

    public boolean join(Community community)
    {
        SnapshotApi api = SnapshotApi.getInstance();
        ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
        params.add(new BasicNameValuePair("user", getCurrentUserId()));
        params.add(new BasicNameValuePair("community", community.toString()));
        api.post(SnapshotApi.SERVICE_USER, UserApi.ACTION_JOIN, params, null);
        return true;
    }
}