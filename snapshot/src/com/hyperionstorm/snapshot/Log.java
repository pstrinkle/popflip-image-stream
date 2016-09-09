package com.hyperionstorm.snapshot;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.widget.Toast;

public class Log
{
    public static class Entry
    {
        public Entry(String description, Exception exception)
        {
            this.exception = exception;
            this.description = description;
            
            SimpleDateFormat sdf = new SimpleDateFormat("MM/dd HH:mm:ss");
            time = sdf.format(new Date());
        }
        public Entry(String description){
            this(description, null);
        }
        public String time;
        public Exception exception;
        public String description;
    }
    
    private static List<Entry> entries = new ArrayList<Entry>();
    
    public static void i(String description)
    {
        i(description, null);
    }
    
    public static void i(String description, Exception ex)
    {
        if(Snapshot.DEBUG)
        {
            entries.add(new Entry(description, ex));
            android.util.Log.i("snapshot", description);
        }
    }
    
    public static List<Entry> getEvents()
    {
        return entries;
    }
}
