package com.hyperionstorm.snapshot.api;

@SuppressWarnings("serial")
public class SnapshotApiException extends Exception
{
    public SnapshotApiException(Exception e)
    {
        super(e);
    }
}