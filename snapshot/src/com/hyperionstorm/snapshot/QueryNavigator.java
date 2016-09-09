package com.hyperionstorm.snapshot;

import java.util.List;

import android.os.AsyncTask;

import com.hyperionstorm.snapshot.api.actions.Post;
import com.hyperionstorm.snapshot.api.actions.Query;

public class QueryNavigator
{

    private class PostCacher extends AsyncTask<Post, Void, Void>
    {
        @Override
        public Void doInBackground(Post... params)
        {
            params[0].cache();
            return null;
        }
    }

    private class PostCleanuper extends AsyncTask<Post, Void, Void>
    {
        @Override
        public Void doInBackground(Post... params)
        {
            params[0].cleanup();
            return null;
        }
    }
    
    private static final int CACHE_COUNT = 3;
    
    private QueryManager queryManager = null;
    private Query lastQuery = null;
    protected int currentPostIndex = 0;
    
    private static QueryNavigator instance;
    
    public QueryNavigator(QueryManager qm)
    {
        instance = this;
        queryManager = qm;
        queryUpdate();
    }
    
    public static QueryNavigator getInstance(){
        return instance;
    }
    
    public QueryManager getManager(){
        return queryManager;
    }
    
    public List<String> getPostIds(){
        if(lastQuery != null){
            return lastQuery.getPostIds();
        } else {
            return null;
        }
    }
    
    public Post getCurrentPost()
    {
        Query cq = queryUpdate();
        if (cq == null)
        {
            return null;
        }
        return cq.getPost(currentPostIndex);
    }
    
    public Post getNextPost()
    {
        Post resultPost = null;
        Query cq = queryUpdate();
        
        if (cq != null)
        {
            currentPostIndex++;
            if (currentPostIndex == (cq.count()))
            {
                currentPostIndex--;
            }

            try
            {
                if ((currentPostIndex + 3) < cq.count())
                {
                    /* kickoff caching in a post (downstream) */
                    Post p = cq.getPost(currentPostIndex + 3);
                    new PostCacher().execute(new Post[] {p});
                }
                if ((currentPostIndex - 3) >= 0)
                {
                    /* remove caching from a post (upstream) */
                    Post p = cq.getPost(currentPostIndex - 3);
                    new PostCleanuper().execute(new Post[] {p});
                }
                
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
            
            resultPost = cq.getPost(currentPostIndex);
        }
        return resultPost;
    }
    
    public Post getPostAtIndex(int index){
        Post resultPost = null;
        Query cq = queryUpdate();
        
        if (cq != null)
        {
//            index--;
//            if (index < 0)
//            {
//                index = 0;
//            }
//            
//            try
//            {
//                if ((index - 3) >= 0)
//                {
//                    /* kickoff caching in a post (upstream) */
//                    Post p = cq.getPost(index - 3);
//                    new PostCacher().execute(new Post[] {p});
//                }
//                if ((index + 3) < cq.count())
//                {
//                    /* remove caching from a post (downstream) */
//                    Post p = cq.getPost(index + 3);
//                    new PostCleanuper().execute(new Post[] {p});
//                }
//            }
//            catch (Exception e)
//            {
//                e.printStackTrace();
//            }
            
            resultPost =  cq.getPost(index);
        }
        return resultPost;
    }
    

    public Post getPrevPost()
    {
        Post resultPost = null;
        Query cq = queryUpdate();
        
        if (cq != null)
        {
            currentPostIndex--;
            if (currentPostIndex < 0)
            {
                currentPostIndex = 0;
            }
            
            try
            {
                if ((currentPostIndex - 3) >= 0)
                {
                    /* kickoff caching in a post (upstream) */
                    Post p = cq.getPost(currentPostIndex - 3);
                    new PostCacher().execute(new Post[] {p});
                }
                if ((currentPostIndex + 3) < cq.count())
                {
                    /* remove caching from a post (downstream) */
                    Post p = cq.getPost(currentPostIndex + 3);
                    new PostCleanuper().execute(new Post[] {p});
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
            
            resultPost =  cq.getPost(currentPostIndex);
        }
        return resultPost;
    }
    
    private Query queryUpdate()
    {
        Query cq = queryManager.getCurrentQuery();
        if ((cq != lastQuery && cq != null) ||
                (null != cq && null == lastQuery))
        {
            /* reset the counters and update the lastQuery */
            currentPostIndex = 0;
            lastQuery = cq;
            
            /* since this is a new query, we should kick off some caching of
             * later posts in the stream.
             */
            int postsToCache = cq.count();
            if (postsToCache > CACHE_COUNT)
            {
                postsToCache = CACHE_COUNT;
            }
            for (int i = 0; i < postsToCache; i++)
            {
                Post p = cq.getPost(i);
                new PostCacher().execute(new Post[] {p});
            }
        }
        return cq;
    }

    public int getCurrentPostIndex()
    {
        return currentPostIndex;
    }

    public void setCurrentPostIndex(int i)
    {
        if (null != lastQuery)
        {
            if ((i < 0) || (i > lastQuery.count()))
            {
                throw new IndexOutOfBoundsException();
            }
            currentPostIndex = i;
            return;
        }
        throw new IllegalStateException();
     }
}
