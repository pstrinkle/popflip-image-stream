package com.hyperionstorm.snapshot;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.Toast;

import com.actionbarsherlock.app.SherlockActivity;
import com.hyperionstorm.snapshot.api.UserApi;
import com.hyperionstorm.snapshot.service.UploadService;
import com.hyperionstorm.snapshot.utilities.ConnectionUtilities;

public class LoginActivity extends SherlockActivity {
	public static final String PREFS_NAME = "HyperionSnapshotsPreferences";

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_activity);
        getSupportActionBar().hide();
        SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
        String username = settings.getString("username", "");
        EditText usernameFieldValue = (EditText) findViewById(R.id.usernameField);
        usernameFieldValue.setText(username);
        usernameFieldValue.setSelection(usernameFieldValue.getText().length());
        getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN);
    }
    
    @Override
    public void onBackPressed()
    {
        /* don't want them to be able to go back to the main screen until they
         * actually log in.
         */
        moveTaskToBack(true);
    }

    public void cancelButtonClick(View v)
    {
        Toast.makeText(this, "You must login to continue.", Toast.LENGTH_LONG).show();
    }
    
    public void loginButtonClick(View v)
    {
        try{
            if(ConnectionUtilities.isConnectivityAvailable(this)) {
                Toast.makeText(LoginActivity.this, "No internet connection available. Unable to login.", Toast.LENGTH_LONG).show();
            }
        } catch(Exception e){
            Toast.makeText(LoginActivity.this, "Error determining connectivity.", Toast.LENGTH_LONG).show();
        }
        
        EditText usernameFieldValue = (EditText) findViewById(R.id.usernameField);
        EditText passwordFiledValue = (EditText) findViewById(R.id.passwordField);
        final String username = usernameFieldValue.getText().toString();
        final String password = passwordFiledValue.getText().toString();
        
        // Save the username
        SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
        SharedPreferences.Editor editor = settings.edit();
        editor.putString("username", username);
        editor.commit();

        final UserApi userApi = UserApi.getInstance();
        class DispatchQueryExecuteTask extends AsyncTask<Void, Void, Void> {
            protected void onPostExecute(Void v) {
                if(userApi.isLoggedIn()){
                    finish();
                }
                else
                {
                    Toast.makeText(LoginActivity.this, "Invalid username or password.", Toast.LENGTH_LONG).show();
                }
            }

            @Override
            protected Void doInBackground(Void... params)
            {
                userApi.logout();
                userApi.loginUser(username);
                return null;
            }

        }
        new DispatchQueryExecuteTask().execute((Void[]) null);
    }
}
