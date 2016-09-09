package com.hyperionstorm.snapshot;

import org.acra.annotation.ReportsCrashes;

import android.app.Application;
import android.os.Debug;

@ReportsCrashes(formKey = "dHZ4cEpQWFJzc0Q4c1ZqbWE4bF9GMlE6MQ") 
public class Snapshot extends Application
{
    public static final boolean DEBUG = true;
    
    @Override
    public void onCreate() {
        super.onCreate();
        if(!Debug.isDebuggerConnected()){
            org.acra.ACRA.init(this);
        }
    }
}
