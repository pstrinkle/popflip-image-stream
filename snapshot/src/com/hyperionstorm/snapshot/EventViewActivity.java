package com.hyperionstorm.snapshot;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.List;

import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.webkit.WebView;
import android.widget.ExpandableListAdapter;

import com.hyperionstorm.snapshot.Log.Entry;

public class EventViewActivity extends Activity {

    private ExpandableListAdapter mAdapter;
    
    @Override
    public void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_event_view);
        String mime = "text/html";
        String encoding = "utf-8";
        List<Entry> events = Log.getEvents();
        String html = "";
        for(Entry e : events)
        {
            String row = "<b>" + e.time + ":</b> " + e.description + "<br/>";
            if(e.exception != null)
            {
                row += "Exception: " + e.exception.getMessage() + "<br/>Stacktrace: " + getStackTraceString(e.exception) + "<br/>";
                html += "<font color='red'>" + row + "</font>";
            }
            else
            {
                html += row;
            }
        }
        
        WebView webview = (WebView)findViewById(R.id.webView);
        webview.loadDataWithBaseURL(null, html, mime, encoding, null);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_event_view, menu);
        return true;
    }
    
    @Override
    public void onBackPressed()
    {
        finish();
    }
    
    public static String getStackTraceString(Exception exception) {
        StringWriter sw = new StringWriter();
        exception.printStackTrace(new PrintWriter(sw));
        return sw.toString();
    }
}
