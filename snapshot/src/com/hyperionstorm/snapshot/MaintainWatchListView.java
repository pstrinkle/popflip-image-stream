package com.hyperionstorm.snapshot;

import java.util.ArrayList;
import java.util.HashMap;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import com.hyperionstorm.snapshot.api.UserApi;

public class MaintainWatchListView extends Activity {

    private UserApi userApi = UserApi.getInstance();
    private HashMap<String,String> nameToIdMap = null;
    private ArrayList<String> names = null;
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_maintain_watch_list_view);
        
        loadWatchList();
    }
    
    private void loadWatchList()
    {
        final MaintainWatchListView thisInstance = this;
        ListView listView = (ListView) findViewById(R.id.userWatchListView);

        nameToIdMap = new HashMap<String, String>();
        names = new ArrayList<String>();
        String[] watchedUserIds = userApi.getCurrentUserInfo().getWatchlist();
        String[] values = new String[watchedUserIds.length];
        
        for(int i = 0; i < watchedUserIds.length; i++)
        {
            values[i] = userApi.getUserInfo(watchedUserIds[i]).getDisplayName();
            try
            {
                nameToIdMap.put(values[i], watchedUserIds[i]);
                names.add(values[i]);
            }
            catch (Exception e)
            {
                /* probably a duplicate */
            }
        }
        
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this,
            android.R.layout.simple_list_item_1, android.R.id.text1, values);

        listView.setAdapter(adapter);
        
        listView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener(){
            public boolean onItemLongClick(
                    AdapterView<?> parent,
                    View view,
                    final int pos,
                    long id) {
                AlertDialog.Builder myAlertDialog = new AlertDialog.Builder(thisInstance);
                myAlertDialog.setTitle("Delete user: ");
                myAlertDialog.setMessage(
                    "Would you like to stop watching user:" + names.get(pos));
                
                myAlertDialog.setPositiveButton("OK", new DialogInterface.OnClickListener() 
                    {
                         public void onClick(DialogInterface arg0, int arg1)
                         {
                             userApi.getCurrentUserInfo().removeWatch(nameToIdMap.get(names.get(pos)));
                             loadWatchList();
                         }
                    });
                myAlertDialog.setNegativeButton("Cancel", new DialogInterface.OnClickListener() 
                    {
                         public void onClick(DialogInterface arg0, int arg1) {
                             
                         }
                    });
                myAlertDialog.show();
                
                return true;
            }
        });
        
        listView.setOnItemClickListener(new OnItemClickListener() 
        {
            public void onItemClick(
                AdapterView<?> parent,
                View view,
                int position,
                long id)
            {
                final int pos = position;
                Log.i("selected userid from watchlist: " + nameToIdMap.get(names.get(pos)));
                Intent userInfoIntent = new Intent(thisInstance, UserInfoViewActivity.class);
                Log.i("created intent");
                userInfoIntent.putExtra("userid", nameToIdMap.get(names.get(pos)));
                Log.i("put extra");
                startActivity(userInfoIntent);
                Log.i("started activity");
            }
          }); 

    }
    
    
    
    @Override
    public void onBackPressed()
    {
        finish();
    }
}
