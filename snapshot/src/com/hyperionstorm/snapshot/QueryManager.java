package com.hyperionstorm.snapshot;

import java.util.ArrayList;

import org.apache.http.message.BasicNameValuePair;

import com.hyperionstorm.snapshot.api.SnapshotApi;
import com.hyperionstorm.snapshot.api.SnapshotApiException;
import com.hyperionstorm.snapshot.api.actions.Query;
import com.hyperionstorm.snapshot.api.actions.Query.QueryType;

public class QueryManager
{
    private class QueryParam
    {
        public String key;
        public String val;
        public QueryParam(String k, String v)
        {
            key = k;
            val = v;
        }
    }

    private SnapshotApi api = null;
    private ArrayList<QueryParam> params = new ArrayList<QueryParam>();
    private QueryType queryType;
    private Query currentQuery;
    
    public SnapshotApi getApi(){
        return api;
    }

    public Query getCurrentQuery()
    {
        return currentQuery;
    }
    
    public void setApi(SnapshotApi sapi)
    {
        api = sapi;
    }
    
    public void setQueryType(QueryType qt)
    {
        queryType = qt;
    }
    
    public void setQueryParam(String k, String v)
    {
        boolean matchedParams = false;
        /* find any matching parameters */
        for (QueryParam qp : params)
        {
            if (qp.key == k)
            {
                qp.val += "," + v;
                matchedParams = true;
            }
        }
        
        if (matchedParams == false)
        {
            QueryParam qp = new QueryParam(k,v);
            params.add(qp);
        }
    }
    
    public void clearQueryParams()
    {
        params.clear();
        queryType = QueryType.QUERY_TYPE_NORM;
    }
    
    public void execute()
    {
        Query resultQuery = null;
        try
        {
            ArrayList<BasicNameValuePair> factors = new ArrayList<BasicNameValuePair>();
            for (QueryParam qp : params)
            {
                factors.add(new BasicNameValuePair(qp.key, qp.val));
            }
            resultQuery = createQuery(factors, queryType);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        
        if (resultQuery != null)
        {
            if (resultQuery.count() > 0)
            {
                if (currentQuery != null)
                {
                    currentQuery.cleanup();
                }
                currentQuery = resultQuery;
            }
        }
    }

    private Query createQuery(ArrayList<BasicNameValuePair> factors, QueryType qt) 
        throws SnapshotApiException
    {
        Query q = new Query(api, factors, qt);
        return q;
    }
}
