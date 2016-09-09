package com.hyperionstorm.snapshot;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.json.JSONObject;

import com.google.android.maps.MapActivity;
import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.UserApi;
import com.hyperionstorm.snapshot.api.UserApi.User;
import com.hyperionstorm.snapshot.api.actions.Post;

import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.SimpleAdapter;
import android.app.Activity;
import android.content.Intent;

public class PostInfoView extends MapActivity {

    Post post = null;
    @Override
    public void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_post_info_view);
        UserApi userApi = UserApi.getInstance();

        try
        {
            JSONObject j = new JSONObject(getIntent().getExtras().getString("post"));
            post = new Post(SnapshotApi.getInstance(), j);
        }
        catch (Exception e)
        {
            e.printStackTrace();
            exit(null,null);
        }
        
        List<Map<String,Object>> data = new ArrayList<Map<String,Object>>();
        
        /* post id */
        Map<String,Object> item = new HashMap<String,Object>();
        item = new HashMap<String,Object>();
        item.put("display_field", "Post");
        item.put("display_value", post.getPostId());
        data.add(item);
        
        /* author */
        item = new HashMap<String,Object>();
        item.put("display_field", "Author");
        User postAuthor = userApi.getUserInfo(post.getAuthor());
        if (postAuthor != null)
        {
            item.put("display_value", postAuthor.getDisplayName());
        }
        else
        {
            item.put("disply_value", post.getAuthor());
        }
        item.put("k","author");
        item.put("v", post.getAuthor());
        item.put("hasInfoView", true);
        data.add(item);
        
        /* creation data */
        item = new HashMap<String,Object>();
        item.put("display_field", "Posted");
        item.put("display_value", post.getCreationDate());
        data.add(item);
        
        /* tags */
        for (String t : post.getTags())
        {
            item = new HashMap<String,Object>();
            item.put("display_field", "Tag");
            item.put("display_value", t);
            item.put("k","tag");
            item.put("v", t);
            data.add(item);
        }
        
        ListView listView = (ListView) findViewById(R.id.postInfoListView);
        SimpleAdapter adapter = new SimpleAdapter(this, data,
                android.R.layout.simple_list_item_2,
                new String[] {"display_field", "display_value"},
                new int[] {android.R.id.text1,
                           android.R.id.text2});
        
        listView.setAdapter(adapter);
        
        final List<Map<String,Object>> listRef = data;
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener()
        {
            public void onItemClick(
                    AdapterView<?> parent,
                    View view,
                    final int pos,
                    long id)
            {
                Map<String,Object> item = listRef.get(pos);
                if (item.containsKey("hasInfoView"))
                {
                    startUserInfoView(post.getAuthor());
                }
            }});
        
        listView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener()
        {
            public boolean onItemLongClick(
                AdapterView<?> parent,
                View view,
                final int pos,
                long id) 
            {
                Map<String,Object> item = listRef.get(pos);
                if (item.containsKey("k") && item.containsKey("v"))
                {
                    exit((String) item.get("k"), (String) item.get("v"));
                }
                return true;
            }
        });
    }
    
    public void onBackPressed()
    {
        exit(null,null);
    }
    
    public void exit(String k, String v)
    {
        if (k == null || v == null)
        {
            k = "";
            v = "";
        }
        
        Intent i = new Intent();
        i.putExtra("param_key", k);
        i.putExtra("param_value", v);
        setResult(RESULT_OK, i);
        finish();
    }
    
    public void startUserInfoView(String userId)
    {
        Log.i("selected userid from watchlist: " + userId);
        Intent userInfoIntent = new Intent(this, UserInfoViewActivity.class);
        userInfoIntent.putExtra("userid", userId);
        startActivity(userInfoIntent);
    }

    @Override
    protected boolean isRouteDisplayed()
    {
        // TODO Auto-generated method stub
        return false;
    }

}
