package com.hyperionstorm.snapshot.utilities;

import android.content.Context;
import android.content.ContextWrapper;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

public class ConnectionUtilities
{
    public static boolean isConnectivityAvailable(ContextWrapper context){
        return isUsingWifi(context) || isUsingMobileData(context);
    }
    
    public static boolean isUsingWifi(ContextWrapper context) {
        ConnectivityManager connectivity = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        NetworkInfo wifiInfo = connectivity.getNetworkInfo(ConnectivityManager.TYPE_WIFI);

        if (wifiInfo != null && wifiInfo.getState() == NetworkInfo.State.CONNECTED
                || wifiInfo.getState() == NetworkInfo.State.CONNECTING) {
            return true;
        }

        return false;
    }
    
    public static boolean isUsingMobileData(ContextWrapper context) {
        ConnectivityManager connectivity = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        NetworkInfo mobileInfo = connectivity
                .getNetworkInfo(ConnectivityManager.TYPE_MOBILE);

        if (mobileInfo != null && mobileInfo.getState() == NetworkInfo.State.CONNECTED
                || mobileInfo.getState() == NetworkInfo.State.CONNECTING) {
            return true;
        }

        return false;
    }
}
