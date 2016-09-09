package com.hyperionstorm.snapshot;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Point;
import android.location.GpsStatus.Listener;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.provider.MediaStore;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Display;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.actionbarsherlock.app.ActionBar;
import com.actionbarsherlock.app.SherlockActivity;
import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.UserApi;
import com.hyperionstorm.snapshot.api.UserApi.Community;
import com.hyperionstorm.snapshot.api.actions.Post;
import com.hyperionstorm.snapshot.api.actions.PostView;
import com.hyperionstorm.snapshot.service.UploadService;
import com.hyperionstorm.snapshot.utilities.BitmapUtilities;

public class NewPostActivity extends SherlockActivity
{
    public static final int UPLOAD_NOTIFICATION = 458109348;
    private UploadService uploadService;
    private boolean mIsBound = false;
    
	/* A place to dump data that we want to persist between orientation changes. */
	static class TempPersist
	{
		private static TempPersist instance = null;
		private String filepath = null;
		private String lastTags = null;
		private String replyToId = null;
		private TempPersist(){}
		static TempPersist getInstance()
		{
			if(instance == null)
				instance = new TempPersist();
			return instance;
		}
		
		void setFilePath(String path)
		{
			filepath = path;
		}
		
		String getFilePath()
		{
			return filepath;
		}
		
		void setLastTags(String tags)
		{
			this.lastTags = tags;
		}
		
		String getLastTags()
		{
			return lastTags;
		}
		
		void setReplyToId(String replyToId)
        {
            this.replyToId = replyToId;
        }
        
        String getReplyToId()
        {
            return replyToId;
        }
	}
	
    class CommunityInString implements CharSequence
    {
        public Community community = null;
        
        public CommunityInString(Community c)
        {
            community = c;
        }
        
        public int length()
        {
            return community.toString().length(); 
        }

        public char charAt(int index)
        {
            return community.toString().charAt(index);
        }

        public CharSequence subSequence(int start, int end)
        {
            return community.toString().subSequence(start, end);
        }
        
        @Override
        public String toString()
        {
            return community.toString();
        }
    }
    
    private CurrentLocation currentLocation = new CurrentLocation();
    class CurrentLocation
    {
        String longitude = null;
        String latitude = null;

        @Override
        public String toString()
        {
            if (latitude == null || longitude == null)
            {
                return null;
            }
            return latitude + ", " + longitude;
        }
    }

    private LocationListener locListener = new MyLocationListener();
    
    class MyLocationListener implements LocationListener, Listener
    {
        public void onLocationChanged(Location location)
        {
            // This needs to stop getting the location data and save the battery power.
            locManager.removeUpdates(locListener);
            
            currentLocation.latitude = String.format("%f", location.getLatitude());
            currentLocation.longitude = String.format("%f", location.getLongitude());

            locManager.removeGpsStatusListener(this);
            locManager.removeUpdates(this);
        }

        public void onStatusChanged(String provider, int status, Bundle extras)
        {
        }

        public void onProviderEnabled(String provider)
        {
        }

        public void onProviderDisabled(String provider)
        {
        }

        public void onGpsStatusChanged(int event)
        {
        }
    }
    
    private CommunityInString[] communityDialogMap = null;
    private final int notificationsID = 1902351731; 
    private static final int PICTURE_ACTION = 0;
    private static final int SELECT_PHOTO_ACTION = 100;
    private SnapshotApi api;
    
    private boolean lockDownPostData = false;
    //private byte[] postData = null;
    private String repostOfId;

    private LocationManager locManager;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        api = SnapshotApi.getInstance();
        setContentView(R.layout.newpost_layout);
        if(uploadService == null){
            doBindService();
        }
        
        final TextView tv = (TextView) findViewById(R.id.newPostOrReply);
        Intent launchIntent = this.getIntent();
        Bundle launchExtras = launchIntent.getExtras();
        if (launchExtras != null)
        {
            if (launchExtras.containsKey("reply_to"))
            {
                TempPersist.getInstance().setReplyToId(launchExtras.getString("reply_to"));
                tv.setText("Reply to post: " + TempPersist.getInstance().getReplyToId());
            }
            else if (launchExtras.containsKey("repost_of"))
            {
                repostOfId = launchExtras.getString("repost_of");
                //byte[] postData = launchExtras.getByteArray("imageData");
                String filename = launchExtras.getString("filename");
                lockDownPostData = true;
                tv.setText("Repost of post: " + repostOfId);
                final ImageView iv = (ImageView) findViewById(R.id.newPostDataView);
                //iv.setImageBitmap(BitmapFactory.decodeByteArray(postData, 0, postData.length));
                iv.setImageBitmap(BitmapFactory.decodeFile(filename));
            }
        }
        else
        {

            tv.setText("New Post!");
        }
        getCurrentLocation();
        
        //uploader = TempPersist.getInstance().getUploader();
        
        final EditText et = (EditText) findViewById(R.id.tagInput);
        et.setSelection(et.getText().length());
        
        // The path is nulled out on cancel, so if the path already exists, then we're recovering from an orientation change.
        String filepath = TempPersist.getInstance().getFilePath();
        if(filepath != null)
        {
            final ImageView iv = (ImageView) findViewById(R.id.newPostDataView);

            iv.setImageBitmap(BitmapUtilities.loadScreenScaledBitmap(filepath, this));
        }
        String tags = TempPersist.getInstance().getLastTags();
        final EditText etext = (EditText) findViewById(R.id.tagInput);
        if(tags != null)
        {
            etext.setText(tags);
        }
        etext.setSelection(etext.getText().length());
        
        
        etext.addTextChangedListener(new TextWatcher() {
            public void afterTextChanged(Editable s) {}
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                TempPersist.getInstance().setLastTags(s.toString());
            }
        });
        
        ActionBar actionBar = getSupportActionBar();
        actionBar.setDisplayHomeAsUpEnabled(true);
    }
    
    /** Gets the current location and update the mobileLocation variable*/
    private void getCurrentLocation() 
    {
        locManager = (LocationManager) this.getSystemService(Context.LOCATION_SERVICE);
        locManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, locListener);
    }

    private File getAlbumDir() {
        File storageDir = null;
        
        if (Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState())) {
              storageDir = new File(Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_PICTURES), "SnapshotAlbum");
              if (storageDir != null) {
                    if (! storageDir.mkdirs()) {
                          if (! storageDir.exists()){
                                return null;
                          }
                    }
              }    
        }
        return storageDir;
    }

    private File createImageFile() throws IOException {
        File storageDir = getAlbumDir();

        String timeStamp = 
            new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        String imageFileName = "snapshot_" + timeStamp + "_";
        File image = File.createTempFile(
            imageFileName, 
            ".jpg", 
            storageDir
        );
        
        return image;
    }

    public void getFromCamera(View v)
    {
        File f;
        try
        {
            f = createImageFile();
        }
        catch (IOException e)
        {
            e.printStackTrace();
            return;
        }
        TempPersist.getInstance().setFilePath(f.getAbsolutePath());
        
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(f));
        startActivityForResult(takePictureIntent, PICTURE_ACTION);
    }
    
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        Bitmap bitmap = null;
        String filepath = null;
        FileInputStream fis = null;
        switch(requestCode)
        {
            case PICTURE_ACTION:
                if (resultCode == Activity.RESULT_OK)
                {
                    filepath = TempPersist.getInstance().getFilePath();
                }
                break;
            case SELECT_PHOTO_ACTION:
            	if (resultCode == Activity.RESULT_OK)
                {
            		Uri selectedImage = data.getData();
                    String[] filePathColumn = {MediaStore.Images.Media.DATA};

                    Cursor cursor = getContentResolver().query(selectedImage, filePathColumn, null, null, null);
                    cursor.moveToFirst();

                    int columnIndex = cursor.getColumnIndex(filePathColumn[0]);
                    filepath = cursor.getString(columnIndex);
                    TempPersist.getInstance().setFilePath(filepath);
                    cursor.close();
                }
            	break;
        }
        
        bitmap = BitmapFactory.decodeFile(filepath);
        ImageView iv = (ImageView) findViewById(R.id.newPostDataView);
        iv.setImageBitmap(bitmap);
        try
        {
            fis = new FileInputStream(new File(filepath));
        }
        catch (FileNotFoundException e)
        {
            e.printStackTrace();
        }
        
        try
        {
            fis.close();
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
    }
    
    public void getFromFile(View v)
    {
    	Intent photoPickerIntent = new Intent(Intent.ACTION_PICK);
    	photoPickerIntent.setType("image/*");
    	startActivityForResult(photoPickerIntent, SELECT_PHOTO_ACTION);   
    }
    
    public void submitPost(View v)
    {   
        if (createPost())
        {
            // null out the bitmap to avoid an OutOfMemoryException when posting a new image.
            final ImageView iv = (ImageView) findViewById(R.id.newPostDataView);
            iv.setImageBitmap(null);
            
            locManager.removeUpdates(locListener);
            Toast.makeText(this, "Post uploading.", Toast.LENGTH_SHORT).show();
            finish();
        }
    }
    
    public void cancelPost(View v)
    {
    	TempPersist.getInstance().setFilePath(null);
        locManager.removeUpdates(locListener);
        Toast.makeText(this, "Post creation cancelled.", Toast.LENGTH_SHORT).show();
        finish();
    }
    
    @Override
    public void onBackPressed()
    {
        cancelPost(null);
    }
    
    private boolean createPost()
    {
        final ArrayList<String> postTags = new ArrayList<String>();
        
        if (TempPersist.getInstance().getFilePath() == null)
        {
            Toast.makeText(this, "Please provide an image!", Toast.LENGTH_SHORT).show();
            return false;
        }
        
        final EditText et = (EditText) findViewById(R.id.tagInput);
        String tagString = et.getText().toString().replace(" ", ",");
        tagString = tagString.toLowerCase();
        String loc = currentLocation.toString();
        /*
         * @todo replace all unacceptable input values
         * tagString = tagString.replace("", "");
         */
        
        if (tagString == "tags" || tagString == ",")
        {
            Toast.makeText(this, "Please provide tags!", Toast.LENGTH_SHORT).show();
            return false;
        }
        
        String[] tags = tagString.split(",");
        for (String tag : tags)
        {
            postTags.add(tag);
        }
        
        Post newPost = null;
        try
        {
            if (TempPersist.getInstance().getReplyToId() != null)
            {
                newPost = new Post(api, postTags, TempPersist.getInstance().getReplyToId(), loc);
            }
            else if (repostOfId != null)
            {
                newPost = new Post(api, postTags, null, loc, repostOfId);
            }
            else
            {
                newPost = new Post(api, postTags, null, loc);
            }
            
        }
        catch (SnapshotApiException e)
        {
            Log.i("Snapshot API error", e);
            return true;
        }
        newPost.addContent(TempPersist.getInstance().getFilePath());
        
        uploadService.AddPost(newPost);
           
        return true;
    }

    public void selectCommunity(View v)
    {
        displayCommunitySelection();
    }
    
    private void displayCommunitySelection()
    {
        Community[] comms = UserApi.getInstance().getCommunities();
        CommunityInString[] items = new CommunityInString[comms.length];
        for (int i = 0; i < comms.length; i++)
        {
            items[i] = new CommunityInString(comms[i]);
        }
        
        communityDialogMap = items;
    
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Select a community:");
        
        builder.setItems(items, new DialogInterface.OnClickListener() 
        {
            public void onClick(DialogInterface dialog, int item) 
            {
                updateTagsWithCommunity(communityDialogMap[item]);
            }
        });
        AlertDialog alert = builder.create();
        alert.show();
    }
    
    private void updateTagsWithCommunity(CommunityInString c)
    {
        final EditText et = (EditText) findViewById(R.id.tagInput);
        et.setText(c.toString());
    }
    
    private ServiceConnection mConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            // This is called when the connection with the service has been
            // established, giving us the service object we can use to
            // interact with the service.  Because we have bound to a explicit
            // service that we know is running in our own process, we can
            // cast its IBinder to a concrete class and directly access it.
            uploadService = ((UploadService.LocalBinder)service).getService();

            // Tell the user about this for our demo.
            Toast.makeText(NewPostActivity.this, "service connected", Toast.LENGTH_SHORT).show();
        }

        public void onServiceDisconnected(ComponentName className) {
            // This is called when the connection with the service has been
            // unexpectedly disconnected -- that is, its process crashed.
            // Because it is running in our same process, we should never
            // see this happen.
            uploadService = null;
            Toast.makeText(NewPostActivity.this, "service disconnected", Toast.LENGTH_SHORT).show();
        }
    };
    
    void doBindService() {
        // Establish a connection with the service.  We use an explicit
        // class name because we want a specific service implementation that
        // we know will be running in our own process (and thus won't be
        // supporting component replacement by other applications).
        bindService(new Intent(NewPostActivity.this, UploadService.class), mConnection, Context.BIND_AUTO_CREATE);
        mIsBound = true;
    }

    void doUnbindService() {
        if (mIsBound) {
            // Detach our existing connection.
            unbindService(mConnection);
            mIsBound = false;
        }
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        doUnbindService();
    }
}
