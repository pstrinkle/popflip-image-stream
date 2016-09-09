package com.hyperionstorm.snapshot.api.admin;

import java.util.ArrayList;

import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.hyperionstorm.snapshot.api.SnapshotApi;

public class AdminApi
{
    public static String USER1_USER_ID = null;

    public static String ACTION_ADMIN = "admin";

    /* these are fake constants, as they need to be initted,
     * but as far as the testing framework is concerned they 
     * are constants.
     */
    public static String DOCTORPOM_SCREEN_NAME = null;
    public static String DOCTORPOM_EMAIL_ADDRESS = null;
    public static String DOCTORPOM_USER_ID = null;
    public static String DOCTORPOM_REAL_NAME = null;
    public static String DOCTORPOM_WEB_HOME = null;
    
    public static JSONArray postsList;
    
    public static JSONArray usersList;
    
    public static boolean hasBeenInitted = false;

    
    public AdminApi()
    {
        super();
        
    }
    
    public static final boolean init()
    {
        if (!hasBeenInitted)
        {
            JSONObject adminResults = null;
            ArrayList<BasicNameValuePair> params = new ArrayList<BasicNameValuePair>();
            params.add(new BasicNameValuePair("code", "58780932341"));
            SnapshotApi api = SnapshotApi.getInstance();
            try
            {
                 adminResults = new JSONObject(new String(api.post(SnapshotApi.SERVICE_SNAPSHOT, ACTION_ADMIN, params, null)));
            }
            catch (JSONException e)
            {
                e.printStackTrace();
                return false;
            }
            
            try
            {
                usersList = adminResults.getJSONArray("users");
                postsList = adminResults.getJSONArray("posts");
            }
            catch (JSONException e)
            {
                e.printStackTrace();
                return false;
            }
            
            try
            {
                getAndSetDoctorPomStuff();
            }
            catch (JSONException e)
            {
                e.printStackTrace();
                return false;
            }
            
            try
            {
                getAndSetUser1Id();
            }
            catch (JSONException e)
            {
                e.printStackTrace();
                return false;
            }
        }
        
        hasBeenInitted = true;
        return true;
    }

    private static void getAndSetUser1Id() throws JSONException
    {
        for(int i = 0; i < usersList.length(); i++)
        {
            JSONObject currentUser = usersList.getJSONObject(i);
            String userName = currentUser.getString("screen_name");
            if (userName.equals("user1"))
            {
                USER1_USER_ID = currentUser.getString("id");
                break;
            }
        }
    }

    private static void getAndSetDoctorPomStuff() throws JSONException
    {
        for(int i = 0; i < usersList.length(); i++)
        {
            JSONObject currentUser = usersList.getJSONObject(i);
            String userName = currentUser.getString("screen_name");
            if (userName.equals("doctorpom"))
            {
                DOCTORPOM_USER_ID = currentUser.getString("id");
                DOCTORPOM_EMAIL_ADDRESS = currentUser.getString("email");
                DOCTORPOM_REAL_NAME = currentUser.getString("realish_name");
                DOCTORPOM_SCREEN_NAME = currentUser.getString("screen_name");
                DOCTORPOM_WEB_HOME = currentUser.getString("home");
                break;
            }
        }
    }
}
