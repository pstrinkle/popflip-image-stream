package com.hyperionstorm.snapshot;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentStatePagerAdapter;
import android.support.v4.view.ViewPager;
import android.view.GestureDetector;
import android.view.GestureDetector.SimpleOnGestureListener;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnLongClickListener;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.actionbarsherlock.app.SherlockFragmentActivity;
import com.actionbarsherlock.view.Menu;
import com.actionbarsherlock.view.MenuInflater;
import com.actionbarsherlock.view.MenuItem;
import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.UserApi;
import com.hyperionstorm.snapshot.api.actions.Post;
import com.hyperionstorm.snapshot.api.actions.PostView;
import com.hyperionstorm.snapshot.api.actions.Query.QueryType;
import com.hyperionstorm.snapshot.guicomponents.SnapshotThumbnailView;
import com.hyperionstorm.snapshot.guicomponents.TouchImageView;
import com.hyperionstorm.snapshot.service.UploadService;

public class SnapshotGui extends SherlockFragmentActivity implements OnClickListener
{
    /**
     * The {@link android.support.v4.view.PagerAdapter} that will provide fragments representing
     * each object in a collection. We use a {@link android.support.v4.app.FragmentStatePagerAdapter}
     * derivative, which will destroy and re-create fragments as needed, saving and restoring their
     * state in the process. This is important to conserve memory and is a best practice when
     * allowing navigation between objects in a potentially large collection.
     */
    PostCollectionPagerAdapter pagerAdapter;
    
    /**
     * The {@link android.support.v4.view.ViewPager} that will display the object collection.
     */
    ViewPager mViewPager;
    
    private static final int LOGIN_REQUEST = 357;
    private static final int POST_INFO_VIEW = 308;
    private static final int REFRESH_VIEW = 223;
    private QueryManager queryManager;
    private static SnapshotGui instance;
    private static QueryNavigator queryNavigator;
    
    private boolean fullscreenToggle = false;
    private boolean pivotOpen = false;
    public static File cacheDir;
    ArrayAdapter<SnapshotThumbnailView> thumbAdapter;
    ArrayList<SnapshotThumbnailView> thumbnails;
    
    private SnapshotApi snapshotApi = null;
    private GestureDetector gestureDetector = null;
    View.OnTouchListener gestureListener = null;
    private Post currentPost;
    private UserApi userApi;
    
    static class TempPersist
    {
        protected TempPersist(){}
        private static TempPersist instance = null;
        public static TempPersist getInstance()
        {
            if(instance == null)
            {
                instance = new TempPersist();
            }
            return instance;
        }
        
        private QueryManager queryManager;
        private UserApi userApi;
        private QueryNavigator queryNavigator;
        private SnapshotApi snapshotApi;
        
        public QueryManager getQueryManager()
        {
            return queryManager;
        }
        public void setQueryManager(QueryManager queryManager)
        {
            this.queryManager = queryManager;
        }
        public UserApi getUserApi()
        {
            return userApi;
        }
        public void setUserApi(UserApi userApi)
        {
            this.userApi = userApi;
        }
        public QueryNavigator getQueryNavigator()
        {
            return queryNavigator;
        }
        public void setQueryNavigator(QueryNavigator queryNavigator)
        {
            this.queryNavigator = queryNavigator;
        }
        public SnapshotApi getSnapshotApi()
        {
            return snapshotApi;
        }
        public void setSnapshotApi(SnapshotApi snapshotApi)
        {
            this.snapshotApi = snapshotApi;
        }
    }
    
//    // Not allowed on fragment views.... then what?
//    @Override
//    public Object onRetainNonConfigurationInstance()
//    {
//        // Return an object containing the things we want to persist. It can be retrieved later with getLastNonConfigurationInstance()
//        
//        final TempPersist storage = TempPersist.getInstance();
//        storage.setQueryManager(queryManager);
//        storage.setUserApi(userApi);
//        storage.setQueryNavigator(queryNavigator);
//        storage.setSnapshotApi(snapshotApi);
//        
//        return storage;
//    }
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        instance = this;
        setContentView(R.layout.main);
        cacheDir = getCacheDir();
        
        queryNavigator = QueryNavigator.getInstance();
        if(queryNavigator != null)
        {
            queryManager = queryNavigator.getManager();
            snapshotApi = queryManager.getApi();
        }
        else
        {
            queryManager = new QueryManager();
            queryNavigator = new QueryNavigator(queryManager);
            snapshotApi = SnapshotApi.getInstance();
            queryManager.setApi(snapshotApi);
        }
        
        /* finally, make sure the user is logged in */
        userApi = UserApi.getInstance();
        startService(new Intent(this, UploadService.class));
        if (!userApi.isLoggedIn())
        {
            Intent loginIntent = new Intent(this, LoginActivity.class);
            startActivityForResult(loginIntent, LOGIN_REQUEST);
        }
        else
        {
            loadOrUpdateMainScreen();
            initPager();
        }
    }
    
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getSupportMenuInflater();
        inflater.inflate(R.menu.mainmenu, menu);
        return true;
    }
    
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
        switch (item.getItemId()) {
            case R.id.newMenuOption:
                createButtonClick(new View(this));
                return true;
            case R.id.replyMenuOption:
                replyButtonClick(new View(this));
                return true;
            case R.id.homeMenuOption:
                getHomeByOptionMenu();
                return true;
            case R.id.publicMenuOption:
                getPublicByOptionMenu();
                return true;
            case R.id.refreshMenuOption:
                refreshByOptionMenu();
                return true;
            case R.id.userInfoMenuOption:
                Intent userInfoIntent = new Intent(this, UserInfoViewActivity.class);
                userInfoIntent.putExtra("userid", userApi.getCurrentUserInfo().getUserId());
                startActivityForResult(userInfoIntent, REFRESH_VIEW);
                return true;
            case R.id.eventLogMenuOption:
                Intent eventIntent = new Intent(this, EventViewActivity.class);
                startActivity(eventIntent);
                return true;
        }
        return false;
    }
    
    private void loadOrUpdateMainScreen()
    {
        if (queryNavigator.getCurrentPost() == null)
        {
            /* by default, load the users home view */
            getHome(null);
        }
        else
        {
            try
            {
                updatePost();
            }
            catch (SnapshotApiException e)
            {
                getHome(null);
            }
        }
    }
    
    public static SnapshotGui getInstance()
    {
        return instance;
    }
    
    // When selecting a thumbnail, get its index from the list and pass it here.
    public static void setCurrentPost(int index)
    {
        SnapshotGui.getInstance().getViewPager().setCurrentItem(index);
    }
    
    public static int getCurrentPost()
    {
        return SnapshotGui.getInstance().getViewPager().getCurrentItem();
    }
    
    public ViewPager getViewPager()
    {
        return mViewPager;
    }
    
    private void initPager()
    {
        pagerAdapter = new PostCollectionPagerAdapter(getSupportFragmentManager());
        mViewPager = (ViewPager) findViewById(R.id.pager);
        mViewPager.setAdapter(pagerAdapter);
    }

    private void dispatchQueryExecute()
    {
        class DispatchQueryExecuteTask extends AsyncTask<Void, Void, Void> {

            @Override
            protected void onPostExecute(Void result) {
                finishProgress();
                
                try
                {
                    currentPost = null;
                    initPager();
                    mViewPager.setOnClickListener(SnapshotGui.this);
                    mViewPager.setOnTouchListener(gestureListener);
                }
                catch (Exception e)
                {
                    e.printStackTrace();
                }
            }

            @Override
            protected Void doInBackground(Void... params)
            {
                queryManager.execute();
                queryNavigator.getCurrentPost();
                return null;
            }

        }
        startProgress();
        new DispatchQueryExecuteTask().execute();
    }
    
    private void startProgress()
    {
        ProgressBar pb = (ProgressBar) findViewById(R.id.mainProgressBar);
        pb.bringToFront();
        pb.setVisibility(View.VISIBLE);
    }
    
    private void finishProgress()
    {
        ProgressBar pb = (ProgressBar) findViewById(R.id.mainProgressBar);
        pb.setVisibility(View.INVISIBLE);
    }
    
    public void getPostInfo(View v)
    {
        try
        {
            Toast.makeText(this,
                currentPost.getPostJson(),
                Toast.LENGTH_LONG).show();
        }
        catch (Exception e)
        {
            Toast.makeText(this,
                "error loading post info",
                Toast.LENGTH_LONG).show();
        }
    }
    
    private void updatePost() throws SnapshotApiException
    {
        currentPost = queryNavigator.getCurrentPost();
//        updateFavButton();
//        updateWatchButton();
//        updatePostInfoText();
        
//        class DispatchQueryExecuteTask extends AsyncTask<Void, Void, PostView> {
//            protected void onPostExecute(PostView v) {
//                scv.update(v);
//            }
//
//            @Override
//            protected PostView doInBackground(Void... params)
//            {
//                PostView v = null;
//                try
//                {
//                    v = currentPost.getPostView();
//                    int retries = 3;
//                    while (v == null)
//                    {
//                        retries--;
//                        if(retries == 0)
//                        {
//                            Toast.makeText(SnapshotGui.this, "Post load failed.", Toast.LENGTH_SHORT).show();
//                            return null;
//                        }
//                        v = currentPost.getPostView();
//                    }
//                }
//                catch (SnapshotApiException e)
//                {
//                    e.printStackTrace();
//                }
//                return v;
//            }
//        }
//        new DispatchQueryExecuteTask().execute((Void[]) null);
    }
    
    public static String getTimeString(long longSeconds)
    {
        longSeconds = (long) Math.sqrt(longSeconds*longSeconds);
        long longMinutes = longSeconds / 60;
        long longHours = longMinutes / 60;
        long longDays = longHours / 24;
        
        int seconds = (int)(longSeconds % 60);
        int minutes = (int)(longMinutes % 60);
        int hours = (int)(longHours % 24);
        int days = (int)longDays;
        
        String timestring = "Taken ";
        if(days > 0)
        {
            timestring += days + " days ";
        }
        if(hours > 0)
        {
            timestring += hours + " hours ";
        }
        if(minutes > 0)
        {
            timestring += minutes + " minutes ";
        }
        if(seconds > 0)
        {
            timestring += seconds + " seconds ";
        }
        timestring += " ago.";
        return timestring;
    }
    
    private void getHomeByOptionMenu()
    {
        getHome(null);
    }

    public void getHome(View v)
    {
        try
        {
            queryManager.clearQueryParams();
            queryManager.setQueryParam("user", userApi.getCurrentUserId());
            queryManager.setQueryType(QueryType.QUERY_TYPE_HOME);
            queryManager.setQueryParam("id", userApi.getCurrentUserId());
            dispatchQueryExecute();
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }
    
    private void getPublicByOptionMenu()
    {
        getPublic(null);
    }
    
    public void getPublic(View v)
    {
        try
        {
            queryManager.clearQueryParams();
            queryManager.setQueryParam("user", userApi.getCurrentUserId());
            queryManager.setQueryType(QueryType.QUERY_TYPE_PUBLIC);
            queryManager.setQueryParam("user", userApi.getCurrentUserId());
            dispatchQueryExecute();
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }
    
    private void refreshByOptionMenu()
    {
        dispatchQueryExecute();
    }
    
    public void pivotOn()
    {
        if(pivotOpen == true){ return; }
        pivotOpen = true;
        if (null != currentPost)
        {
            // custom dialog
            final Dialog dialog = new Dialog(this);
            dialog.setContentView(R.layout.pivot_dialog);
            dialog.setTitle("PIVOT");
            
            dialog.setOnDismissListener(new android.content.DialogInterface.OnDismissListener() {
                @Override
                public void onDismiss(final DialogInterface arg0) {
                    pivotOpen = false;
                }
            });
            
            Button b = (Button) dialog.findViewById(R.id.pivotOnAuthorButton);
            b.setOnClickListener(new OnClickListener() 
            {
                public void onClick(View v) 
                {
                    pivotOn("author", currentPost.getAuthor());
                    dialog.dismiss();
                }
            });
            
            b = (Button) dialog.findViewById(R.id.pivotOnRepliesButton);
            if (currentPost.hasReplies())
            {
                b.setVisibility(View.VISIBLE);
                b.setOnClickListener(new OnClickListener() 
                {
                    public void onClick(View v) 
                    {
                        pivotOn("reply_to",currentPost.getPostId());
                        dialog.dismiss();
                    }
                });
            }
            
            
            ArrayList<String> postTags = currentPost.getTags();
            int[] buttonIds = new int[]
                    {
                        R.id.pivotTag1Button,
                        R.id.pivotTag2Button,
                        R.id.pivotTag3Button,
                    };
            
            for (int i = 0; i < buttonIds.length; i++)
            {
                String currentTag = null;
                try
                {
                    currentTag = postTags.get(i);
                }
                catch (IndexOutOfBoundsException e)
                {
                    currentTag = null;
                }
                
                if (currentTag != null)
                {
                    final String tag = currentTag;
                    Button pivotButton = (Button) dialog.findViewById(buttonIds[i]);
                    pivotButton.setText(tag);
                    pivotButton.setVisibility(View.VISIBLE);
                    pivotButton.setOnClickListener(new OnClickListener() 
                    {
                        public void onClick(View v) 
                        {
                            pivotOn("tag", tag);
                            dialog.dismiss();
                        }
                    });
                }
                else
                {
                    Button pivotButton = (Button) dialog.findViewById(buttonIds[i]);
                    pivotButton.setText("");
                    pivotButton.setVisibility(View.INVISIBLE);
                }
            }
            
            dialog.show();
        }
    }
    
    private void pivotOn(String k, String v)
    {
        if (k != "" && v != "")
        {
            try
            {
                Toast.makeText(this, "Loading stream...", Toast.LENGTH_SHORT).show();
                queryManager.clearQueryParams();
                queryManager.setQueryParam("user", userApi.getCurrentUserId());
                queryManager.setQueryType(QueryType.QUERY_TYPE_NORM);
                queryManager.setQueryParam(k, v);
                dispatchQueryExecute();
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
        }
    }
    
    public void replyButtonClick(View v)
    {
        /* should start the NewPostActivity with a postId param */
        Intent createPostIntent = new Intent(v.getContext(), NewPostActivity.class);
        if (currentPost != null)
        {
            createPostIntent.putExtra("reply_to", currentPost.getPostId());
            startActivityForResult(createPostIntent, 0);
        }
    }
    
    public void repostButtonClick(View v)
    {
        /* should start the NewPostActivity with a postId param */
        Intent createPostIntent = new Intent(v.getContext(), NewPostActivity.class);
        if (currentPost != null)
        {
            createPostIntent.putExtra("repost_of", currentPost.getPostId());
            try
            {
                createPostIntent.putExtra("filename", currentPost.getPostView().getFilename());
                //createPostIntent.putExtra("imageData", currentPost.getPostView().getRaw());
            }
            catch (SnapshotApiException e)
            {
                e.printStackTrace();
                Toast.makeText(
                    getApplicationContext(),
                    "Error getting current posts image!",
                    Toast.LENGTH_LONG).show();
                return;
            }
            startActivityForResult(createPostIntent, 0);
        }
    }

    public void createButtonClick(View v)
    {
        Intent createPostIntent = new Intent(v.getContext(), NewPostActivity.class);
        startActivityForResult(createPostIntent, 0);
    }
    
    public void favButtonToggle(View v)
    {
//        if (currentPost.isFavorited())
//        {
//            currentPost.unfavorite();
//        }
//        else
//        {
//            currentPost.favorite();
//        }
//        updateFavButton();
    }
    
    public void watchButtonToggle(View v)
    {
//        ToggleButton tb = (ToggleButton) findViewById(R.id.watchToggleButton);
//        if (!tb.isChecked())
//        {
//            userApi.getCurrentUserInfo().removeWatch(currentPost.getAuthor());
//        }
//        else
//        {
//            userApi.getCurrentUserInfo().addWatch(currentPost.getAuthor());
//        }
    }
    
    /* Based on code borrowed from here: 
       http://stackoverflow.com/questions/937313/android-basic-gesture-detection */
    class MyGestureDetector extends SimpleOnGestureListener
    {
        @Override
        public boolean onSingleTapConfirmed(MotionEvent e){
            toggleFullscreen();
            return true;
        }
    }
    
    private void toggleFullscreen()
    {
        if(fullscreenToggle == true) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            getSupportActionBar().show();
            fullscreenToggle = false;
        } else
        {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
            getSupportActionBar().hide();
            fullscreenToggle = true;
        }
    }
    
    protected void onActivityResult(
        int requestCode,
        int resultCode,
        Intent data) 
    {
        switch(requestCode)
        {
            case LOGIN_REQUEST:
                loadOrUpdateMainScreen();
                break;
            case POST_INFO_VIEW:
                String k = data.getStringExtra("param_key");
                String v = data.getStringExtra("param_value");
                if (k.equals(""))
                {
                    break;
                }
                pivotOn(k, v);
                break;
            case REFRESH_VIEW:
                loadOrUpdateMainScreen();
                break;
        }
    
    }
    
    public void postInfoViewStart(View v)
    {
        if (currentPost != null)
        {
            Intent i = new Intent(this, PostInfoView.class);
            i.putExtra("post", currentPost.getPostJson());
            startActivityForResult(i, POST_INFO_VIEW);
        }
    }

    // Note that this onClick, even left empty, must be here for gesture detection to function.
    public void onClick(View v)
    {
        
    }
    
    /**
     * A {@link android.support.v4.app.FragmentStatePagerAdapter} that returns a fragment
     * representing an object in the collection.
     */
    public static class PostCollectionPagerAdapter extends FragmentStatePagerAdapter {

        
        public PostCollectionPagerAdapter(FragmentManager fm) {
            super(fm);
        }

        @Override
        public Fragment getItem(int i) {
            queryNavigator.setCurrentPostIndex(i);
            Log.i("Getting Pager Item: " + Integer.toString(i));
            Fragment fragment = new PostObjectFragment();
            return fragment;
        }

        @Override
        public int getCount() {
            List<String> postIds = queryNavigator.getPostIds();
            if(postIds != null)
            {
                return postIds.size();
            }
            else
            {
                return 0;
            }
        }
    }

    /**
     * A dummy fragment representing a section of the app, but that simply displays dummy text.
     */
    public static class PostObjectFragment extends Fragment {

        @Override
        public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
            View rootView = inflater.inflate(R.layout.fragment_collection_object, container, false);
            final TouchImageView scv = ((TouchImageView) rootView.findViewById(android.R.id.text1));
            scv.setImageResource(R.drawable.loading);
            
            class SetImageTask extends AsyncTask<Void, Bitmap, Bitmap> {

                protected void onPostExecute(Bitmap bm) {
                    if(bm != null){
                        scv.setImageBitmap(bm);
                    }
                }

                @Override
                protected Bitmap doInBackground(Void... params)
                {
                    try
                    {
                        Post post = queryNavigator.getCurrentPost();
                        PostView pv = post.getPostView();
                        scv.setPost(post);
                        return pv.getImage();
                    }
                    catch (SnapshotApiException e)
                    {
                        e.printStackTrace();
                    }
                    return null;
                }

            }
            new SetImageTask().execute();
            
            return rootView;
        }
    }
}
