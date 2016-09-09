package com.hyperionstorm.snapshot;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import com.hyperionstorm.snapshot.api.UserApi;
import com.hyperionstorm.snapshot.api.UserApi.User;

public class UserInfoViewActivity extends Activity {

    private UserApi userApi;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setResult(RESULT_OK);
        setContentView(R.layout.activity_user_info_view);
        userApi = UserApi.getInstance();
        
        if (userApi.isLoggedIn())
        {
            populateFields();
        }
        else
        {
            finish();
        }
    }

    private void populateFields()
        {
        Intent myIntent = getIntent();
            String userid = myIntent.getStringExtra("userid");
        
        Boolean enabled = false;
        if(userid.equals(userApi.getCurrentUserInfo().getUserId()))
        {
            enabled = true;
        }
        
        Log.i("userid: " + userid);
        User user = userApi.getUserInfo(userid);
        Log.i("user name: " + user.getScreenName());

        if (user != null)
        {
            EditText fieldVal = (EditText) findViewById(R.id.dnValue);
            fieldVal.setText(user.getDisplayName());
            fieldVal.setEnabled(enabled);
            fieldVal = (EditText) findViewById(R.id.rnValue);
            fieldVal.setText(user.getRealName());
            fieldVal.setEnabled(enabled);
            fieldVal = (EditText) findViewById(R.id.snValue);
            fieldVal.setText(user.getScreenName());
            fieldVal.setEnabled(enabled);
            fieldVal = (EditText) findViewById(R.id.eMailValue);
            fieldVal.setText(user.getEMailAddress());
            fieldVal.setEnabled(enabled);
            fieldVal = (EditText) findViewById(R.id.webHomeValue);
            fieldVal.setText(user.getWebHome());
            fieldVal.setEnabled(enabled);
        }
        else
        {
            /* this is not dead code, when the user api excepts, null is ret */
            Toast.makeText(this, "Error loading user info.", Toast.LENGTH_LONG).show();
            finish();
        }
    }
    
    public void startWatchListView(View v)
    {
        Intent i = new Intent(this, MaintainWatchListView.class);
        startActivity(i);
    }
    
    
    public void startCommunitiesView(View v)
    {
        Intent i = new Intent(this, CommunityViewActivity.class);
        startActivity(i);
    }

}
