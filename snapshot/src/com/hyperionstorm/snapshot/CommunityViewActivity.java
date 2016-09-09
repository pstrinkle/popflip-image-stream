package com.hyperionstorm.snapshot;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ListView;

import com.hyperionstorm.snapshot.api.UserApi;
import com.hyperionstorm.snapshot.api.UserApi.Community;

public class CommunityViewActivity extends Activity {

    private Community specialCommunity = null;
    private Community[] myCommunities = null;
    private UserApi userApi = UserApi.getInstance();
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.community_activity_view);
        specialCommunity = userApi.new Community("Join...", null);
        loadCommunityList();
    }
    
    private void loadCommunityList()
    {
        final CommunityViewActivity thisInstance = this;
        ListView listView = (ListView) findViewById(R.id.userCommunityListView);
        Community[] communities = userApi.getCommunities();
        myCommunities = new Community[communities.length + 1];
        
        for (int i = 0; i < communities.length; i++)
        {
            myCommunities[i] = communities[i];
        }
        
        /* the last element is the add new */
        myCommunities[communities.length] = specialCommunity;
        
        ArrayAdapter<Community> adapter = new ArrayAdapter<Community>(this,
            android.R.layout.simple_list_item_1, android.R.id.text1, myCommunities);

        listView.setAdapter(adapter);
        
        listView.setOnItemClickListener(new OnItemClickListener() 
        {
            public void onItemClick(
                AdapterView<?> parent,
                View view,
                int position,
                long id)
            {
                final int pos = position;
                if (myCommunities[pos].equals(specialCommunity))
                {
                    AlertDialog.Builder alert = new AlertDialog.Builder(thisInstance);

                    alert.setTitle("Title");
                    alert.setMessage("Message");

                    // Set an EditText view to get user input 
                    final EditText input = new EditText(thisInstance);
                    alert.setView(input);

                    alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                          String values[] = input.getText().toString().split(",");
                          userApi.join(userApi.new Community(values[0], values[1]));
                          loadCommunityList();
                      }
                    });

                    alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                      public void onClick(DialogInterface dialog, int whichButton) {
                        // Canceled.
                      }
                    });
                    alert.show();

                    return;
                }
                
                AlertDialog.Builder myAlertDialog = new AlertDialog.Builder(thisInstance);
                myAlertDialog.setTitle("Leave Community?");
                myAlertDialog.setMessage(
                    "Would you like to leave the community:" + myCommunities[position]);
                
                myAlertDialog.setPositiveButton("OK", new DialogInterface.OnClickListener() 
                    {
                         public void onClick(DialogInterface arg0, int arg1)
                         {
                             userApi.leave(myCommunities[pos]);
                             loadCommunityList();
                         }
                    });
                myAlertDialog.setNegativeButton("Cancel", new DialogInterface.OnClickListener() 
                    {
                         public void onClick(DialogInterface arg0, int arg1) {
                             
                         }
                    });
                myAlertDialog.show();
            }
          }); 

    }
}
