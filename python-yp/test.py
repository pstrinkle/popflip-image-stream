# -*- coding: utf-8

'''The program needs to run some tests; including trying to get invalid 
input/output going.  I can't run unit-tests locally because I don't have a 
mongo database installed.  I guess I could set it all up here too.

In the interim this program will try to throw good and bad at the API server 
and verify it gets the appropriate responses. 

It will later also test python-yawningpanda, although that testing is less 
important.
'''

import sys
import json as simplejson
import urllib
import urllib2
import unittest
import yawningpanda as yp

def grab_post(post_id):
    """Run snapshot/get and return the user dictionary."""

    url = "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_GET)
    api = ApiHandler()

    resp = api.fetch(url, {"id" : post_id})

    return simplejson.loads(api.get_raw(resp))[0]

def delete_post(post_id):
    """Call snapshot/delete."""

    url = "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_DELETE)
    api = ApiHandler()

    api.fetch(url, None, {"id" : post_id, "code" : 58780932341})

def create_post(author):
    """Create a post; returns the id, so you can delete it."""

    url = "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_CREATE)
    api = ApiHandler()

    params = {"author" : author,
              "tags" : "valid, author, newtest", # cannot use tag test, or the create/delete will fail.
              "code" : 98098098098,
              "data" : open("test-img/photo.jpg", "rb")} 
    # location is optional.
        
    resp = api.fetchmp(url, None, params)
    new_id = simplejson.loads(resp)["id"]

    return new_id


def delete_user(user_identifier):
    """Delete a user created for testing."""

    api = ApiHandler()

    api.fetch("%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_DELETE),
              None,
              {"id" : user_identifier, "code" : 58780932341})

    return

def create_user(screen_name):
    """Create a user for testing."""

    url = "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_CREATE)
    api = ApiHandler()

    resp = api.fetch(url, None, {"realish_name" : "testguy",
                                 "display_name" : screen_name,
                                 "code" : 98098098098,
                                 "email" : "user@whatever.com"})
    try:
        response_data = simplejson.loads(api.get_raw(resp))
    except ValueError:
        raise Exception("Fuck")

    # will have a KeyError if it failed.
    return response_data["id"]
    
def grab_user(user_identifier):
    """Run user/get and return the user dictionary."""

    api = ApiHandler()

    resp = api.fetch("%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_GET),
                     {"id" : user_identifier})

    return simplejson.loads(api.get_raw(resp))

def query_admin(request = None):
    """Run the admin query."""
        
    url = "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_ADMIN)
    api = ApiHandler()
        
    if request is None:
        resp = api.fetch(url, None, {"code" : 58780932341})
    else:
        resp = api.fetch(url, None, {"code" : 58780932341,
                                     "request" : request})
        
    data = simplejson.loads(api.get_raw(resp))
        
    return data

class ApiHandler(object):
    """Simple class for calling API functions."""
    
    def __init__(self):
        pass
    
    def get_raw(self, response):
        """Get the Raw data."""
        
        length = response.headers.get('content-length', None)
        
        #if length is None:
        return response.read()
    
    def _parse(self, params):
        """dictionary of key,value pairs."""
        
        if params is None:
            return None

        quotelist = []
        for k, v in params.items():
            if v is not None:
                quotelist.append("%s=%s" % (str(k), str(urllib.quote(str(v)))))
            else:
                quotelist.append("%s" % str(k))

        return "&".join(quotelist)

#        return urllib.urlencode(dict([(k, v) for k, v in params.items() \
#                                      if v is not None]))
    
    def _build(self, url, params):
        """Build URL."""
        
        if params:
            #url_str = url + '?' + self._parse(params) 
            return url + '?' + self._parse(params)

        return url
    
    def fetchmp(self, url, params, post_data):
        """Grab the results for the URL built."""
        
        raw = None

        from poster.encode import multipart_encode
        from poster.streaminghttp import register_openers
        
        register_openers()
        datagen, headers = multipart_encode(post_data)
        request = urllib2.Request(url, datagen, headers)
        try:
            raw = urllib2.urlopen(request).read()
        except urllib2.HTTPError, e:
            raw = str(e)

        return raw
    
    def fetch(self, url, params, post_data=None):
        """Grab the results for the URL built."""

        response = None
        http_handler  = urllib2.HTTPHandler()

        opener = urllib2.OpenerDirector()
        opener.add_handler(http_handler)

        try:
            response = \
                opener.open(self._build(url, params), self._parse(post_data))
        except urllib2.HTTPError, e:
            print e

        opener.close()

        return response

class TestSnapshotFunctions(unittest.TestCase):
    """."""
    
    # XXX: This is an interesting way of doing this; need to move into the
    # yawningpanda python library.
    base_urls = \
        {
            yp.API_COMMENT :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_COMMENT),
            yp.API_COMMENTS :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_COMMENTS),
            yp.API_CLEANUP :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_CLEANUP),
            yp.API_CREATE :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_CREATE),
            yp.API_DELETE :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_DELETE),
            yp.API_FAVORITE :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_FAVORITE),
            yp.API_GET :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_GET),
            yp.API_HOME :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_HOME),
            yp.API_PUBLIC:
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_PUBLIC),
            yp.API_QUERY :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_QUERY),
            yp.API_REPLY :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_REPLY),
            yp.API_REPORT : 
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_REPORT),
            yp.API_REPOST :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_REPOST),
            yp.API_VIEW :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_VIEW),
            yp.API_UNFAVORITE :
                "%s/%s/%s" % (yp.BASE_URL, yp.POST_URL, yp.API_UNFAVORITE)
        }
        
    valid_author = ''
    valid_screen_name = ''
    valid_tag = ''
    new_post = ''
    fresh_user = {}

    def setUp(self):
        """Call before every test case."""

        data = query_admin()

        if len(data["posts"]) < 1:
            raise Exception("Insufficient Posts Pre-built")

        self.valid_tag = data["posts"][0]["tags"][0]
        self.valid_tag2 = None

        for post in data["posts"]:
            if len(post["tags"]) > 1:
                self.valid_tag2 = post["tags"][1]
        
        if self.valid_tag2 is None:
            raise Exception("Insufficient Tags within Posts")
        
        self.fresh_user[0] = create_user("testguy_fresh")
        self.fresh_user[1] = create_user("testguy_fresh2")
        
        self.valid_author = self.fresh_user[0]
        self.valid_screen_name = "testguy_fresh"
        
        self.new_post = create_post(self.valid_author)
    
    def tearDown(self):
        """Call after every test case.
        
        Everything created is deleted."""

        delete_user(self.fresh_user[0])
        delete_user(self.fresh_user[1])

        del self.fresh_user[0]
        del self.fresh_user[1]
        
        delete_post(self.new_post)
        self.new_post = None

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_QUERY], {"tag" : "test"})
        data = simplejson.loads(api.get_raw(resp))

        for post in data:
            api.fetch(self.base_urls[yp.API_DELETE],
                      None,
                      {"code" : 58780932341, "id" : str(post["id"])})
            
        

    ###########################################################################
    ## --------------- snapshot/comment
    ###########################################################################
    
    # for post in collection.find():
    #     collection.update({"_id" : post["_id"]}, {"$set" : {"comments" : 0}})
    #
    # XXX: Currently you cannot delete comments.
    # Deleting the user will delete their comments; so everything goes clean, 
    # also deleting the post deletes its comments.

    def test_invalid_comment_param(self):
        """Call snapshot/comment with an invalid parameter."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_COMMENT],
                         None,
                         {"yo" : self.valid_author, # user
                          "post" : self.new_post,
                          "comment" : 'blah'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_comment_value(self):
        """Call snapshot/comment with an invalid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_COMMENT],
                         None,
                         {"user" : 'invalid',
                          "post" : self.new_post,
                          "comment" : 'blah'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_comment_toolong(self):
        """Call snapshot/comment with a comment that is too long, but you're
        authorized to post."""
        
        self.assertTrue(False, "Test not implemented.")

    def test_invalid_comment_notauth(self):
        """Call snapshot/comment when you're not authorized."""

        api = ApiHandler()

        # self.new_post was created by self.fresh_user[0]
        resp = api.fetch(self.base_urls[yp.API_COMMENT],
                         None,
                         {"user" : self.fresh_user[1],
                          "post" : self.new_post,
                          "comment" : 'blah blah blah'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_valid_comment_ownpost(self):
        """Call snapshot/comment on your own post."""

        api = ApiHandler()
        
        post_data = grab_post(self.new_post)
        comment_count = post_data["comments"]
        
        params = {"user" : self.fresh_user[0],
                  "post" : self.new_post,
                  "comment" : 'blah blah blah'}

        # self.new_post was created by self.fresh_user[0]
        resp = api.fetch(self.base_urls[yp.API_COMMENT],
                         None,
                         params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))
        self.assertTrue(data["comment"] == params["comment"],
                        "Comment doesn't match.")
        self.assertTrue(data["user"] == params["user"])

        # XXX: test retrieve comments.
        post_data = grab_post(self.new_post)
        
        self.assertTrue(comment_count + 1 == post_data["comments"],
                        "Post comment count not expected value.")

    def test_valid_comment(self):
        """Call snapshot/comment correctly."""
        
        api = ApiHandler()
        
        post_data = grab_post(self.new_post)
        comment_count = post_data["comments"]
        params = {"user" : self.fresh_user[1],
                  "post" : self.new_post,
                  "comment" : 'blah blah blah'}
        
        # self.fresh_user[0] created the post, so s/he has to authorize
        # self.fresh_user[1].
        
        resp = api.fetch("%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_AUTHORIZE),
                         None,
                         {"authorized" : self.fresh_user[1],
                          "authorizer" : self.fresh_user[0]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        resp = api.fetch(self.base_urls[yp.API_COMMENT],
                         None,
                         params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))
        self.assertTrue(data["comment"] == params["comment"],
                        "Comment doesn't match.")
        self.assertTrue(data["user"] == params["user"])

        # XXX: test retrieve comments.
        post_data = grab_post(self.new_post)
        
        self.assertTrue(comment_count + 1 == post_data["comments"],
                        "Post comment count not expected value.")

    ###########################################################################
    ## --------------- snapshot/comments
    ###########################################################################

    # self.fresh_user[0] created the post, so s/he has to authorize
    # self.fresh_user[1].
    def test_invalid_comments_param(self):
        """Call snapshot/comments with an invalid parameter."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_COMMENTS],
                         None,
                         {"yo" : self.fresh_user[0], "post" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_comments_value(self):
        """Call snapshot/comments with an invalid value, such as the post 
        id."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_COMMENTS],
                         None,
                         {"user" : self.fresh_user[0], "post" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_comments_notauth(self):
        """Call snapshot/comments with an unauthorized user."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_COMMENTS],
                         None,
                         {"user" : self.fresh_user[1], "post" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_comments_ownpost(self):
        """Call snapshot/comments with a post we own."""

        api = ApiHandler()

        # retrieve empty
        resp = api.fetch(self.base_urls[yp.API_COMMENTS],
                         None,
                         {"user" : self.fresh_user[0], "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(len(data) == 0, "Must return zero entries...")

        comments = ("blah blah blah 1", "blah blah blah 2", "blah blah blah 3")
        for comment in comments:
            resp = api.fetch(self.base_urls[yp.API_COMMENT],
                             None,
                             {"user" : self.fresh_user[0],
                              "post" : self.new_post,
                              "comment" : comment})

            self.assertTrue(200 == resp.code,
                            "Received an invalid code: %d" % resp.code)

        resp = api.fetch(self.base_urls[yp.API_COMMENTS],
                         None,
                         {"user" : self.fresh_user[0], "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(len(data) == 3, "Must return at least 1 entry...")

        self.assertTrue(data[0]["comment"] == comments[2], "Ordered incorrectly.")
        self.assertTrue(data[0]["user"] == self.fresh_user[0], "Invalid author recorded.")
        self.assertTrue(data[1]["comment"] == comments[1], "Ordered incorrectly.")
        self.assertTrue(data[1]["user"] == self.fresh_user[0], "Invalid author recorded.")
        self.assertTrue(data[2]["comment"] == comments[0], "Ordered incorrectly.")
        self.assertTrue(data[2]["user"] == self.fresh_user[0], "Invalid author recorded.")

    def test_valid_comments(self):
        """Call snapshot/comments with everything OK."""

        api = ApiHandler()

        # self.fresh_user[0] created the post, so s/he has to authorize
        # self.fresh_user[1].
        resp = api.fetch("%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_AUTHORIZE),
                         None,
                         {"authorized" : self.fresh_user[1],
                          "authorizer" : self.fresh_user[0]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        comments = ("blah blah blah 1", "blah blah blah 2", "blah blah blah 3")
        for comment in comments:
            resp = api.fetch(self.base_urls[yp.API_COMMENT],
                             None,
                             {"user" : self.fresh_user[0],
                              "post" : self.new_post,
                              "comment" : comment})

            self.assertTrue(200 == resp.code,
                            "Received an invalid code: %d" % resp.code)

        resp = api.fetch(self.base_urls[yp.API_COMMENTS],
                         None,
                         {"user" : self.fresh_user[1], "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))
        
        self.assertTrue(len(data) == 3, "Must return at least 1 entry...")
        
        self.assertTrue(data[0]["comment"] == comments[2], "Ordered incorrectly.")
        self.assertTrue(data[0]["user"] == self.fresh_user[0], "Invalid author recorded.")
        self.assertTrue(data[1]["comment"] == comments[1], "Ordered incorrectly.")
        self.assertTrue(data[1]["user"] == self.fresh_user[0], "Invalid author recorded.")
        self.assertTrue(data[2]["comment"] == comments[0], "Ordered incorrectly.")
        self.assertTrue(data[2]["user"] == self.fresh_user[0], "Invalid author recorded.")

    ###########################################################################
    ## --------------- snapshot/get
    ###########################################################################
    
    def test_invalid_get_param(self):
        """Call snapshot/get with an invalid parameter."""
        
        url = self.base_urls[yp.API_GET]
        api = ApiHandler()
        
        resp = api.fetch(url, {"yam" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_get_value(self):
        """Call snapshot/get with an inavlid value."""

        url = self.base_urls[yp.API_GET]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_get(self):
        """Call snapshot/get with a valid parameter (and value)"""

        url = self.base_urls[yp.API_GET]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        # XXX: add response parser?
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(data[0]["id"] == self.new_post,
                        "Data not as expected")

    def test_valid_get_asuser(self):
        """Call snapshot/get with valid input and as a user."""

        url = self.base_urls[yp.API_GET]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : self.new_post,
                               "user" : self.valid_author})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        # XXX: add response parser?
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(data[0]["id"] == self.new_post,
                        "Data not as expected")
        
        self.assertTrue("favorite_of_user" in data[0],
                        "User parameter not respected")

    ###########################################################################
    ## --------------- snapshot/query
    ###########################################################################

    def test_invalid_query_param(self):
        """Call snapshot/query with an invalid parameter."""

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        
        resp = api.fetch(url, {"yam" : self.valid_author})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_query_value(self):
        """Call snapshot/query with an invalid value, for author and then tag.
        """

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        
        resp = api.fetch(url, {"author" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # querying for tags cannot really get an invalid string value.
    
    def test_invalid_query_optional_user(self):
        """Call the query with the user field, but with an invalid user."""

        api = ApiHandler()

        favorites = query_admin("favorites")["favorites"]

        # Check to verify favorites.
        self.assertTrue(len(favorites) > 0,
                        "Must be at least one favorited post.")

        favorite_post = favorites[0]["post"]
        
        url = self.base_urls[yp.API_GET] # XXX: returns array of one.
        resp = api.fetch(url, {"id" : favorite_post})        
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)[0]

        author_of_post = data["author"]
        
        url = self.base_urls[yp.API_QUERY]
        resp = api.fetch(url, {"author" : author_of_post,
                               "user" : 'invalid'})
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)

        # This should return the entry we're looking for.
        found = False
        for post in data:
            #print post["id"]
            if post["id"] == favorite_post:
                found = True
                self.assertTrue(post["favorite_of_user"] == False,
                                "Post should not indicate that it's been favorited by user")
                break

        self.assertTrue(found, "Entry must have been returned by author query.")

    def test_invalid_query_optional_since(self):
        """Call the query with the since field, but with an invalid user."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_QUERY],
                         {"tag" : self.valid_tag, "since" : 'invalid'})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        last_len = len(data)

        self.assertTrue(last_len > 2,
                        "Must return at least 1 entry for tag: %s." \
                            % self.valid_tag)

    def test_valid_query_screen_name(self):
        """Call snapshot/query with a valid author."""

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        
        resp = api.fetch(url, {"screen_name" : self.valid_screen_name})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 0, "Must return at least 1 entry.")
    
    def test_valid_query_author(self):
        """Call snapshot/query with a valid author."""

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        
        resp = api.fetch(url, {"author" : self.valid_author})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 0, "Must return at least 1 entry.")

    def test_valid_query_tag(self):
        """Call snapshot/query with a valid tag."""

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        
        resp = api.fetch(url, {"tag" : self.valid_tag})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 0,
                        "Must return at least 1 entry for tag: %s." \
                            % self.valid_tag)

    def test_valid_query_community(self):
        """Call snapshot/query with a valid community."""

        # XXX: The thing should really identify a set of tags that is in common
        # between multiple posts; this may not exactly happen though. lol.

        communities = query_admin("communities")["communities"]

        self.assertTrue(len(communities) > 0,
                        "Must be at least one person in one community" + 
                        " for this test to guarantee to work.")

        community = communities[0]["community"]

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        resp = api.fetch(url, {"community" : ",".join(community)})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(len(data) > 0, "Must return at least 1 entry...")

    def test_valid_query_reply(self):
        """Call snapshot/query with a valid reply_to."""

        # create two replies.
        self.test_valid_reply()
        self.test_valid_reply()
        
        reply_to = None
        
        data = query_admin("posts")
        for post in data["posts"]:
            if post["num_replies"] > 1:
                reply_to = post["id"]

        self.assertTrue(reply_to is not None, "The reply creates failed.")

        url = self.base_urls[yp.API_QUERY]
        params = {"reply_to" : reply_to}
        
        api = ApiHandler()
        resp = api.fetch(url, params)
        
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 1, "Must return at least 2 entries.")

    def test_valid_query_repost(self):
        """Call snapshot/query with a valid repost_of."""

        # create two replies.
        self.test_valid_repost()
        self.test_valid_repost()
        
        repost_of = None
        
        data = query_admin("posts")
        for post in data["posts"]:
            if post["num_reposts"] > 1:
                repost_of = post["id"]

        self.assertTrue(repost_of is not None, "The repost creates failed.")

        url = self.base_urls[yp.API_QUERY]
        params = {"repost_of" : repost_of}
        
        api = ApiHandler()
        resp = api.fetch(url, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 1, "Must return at least 2 entries.")
    
    def test_valid_query_optional_user(self):
        """Call snapshot/query with a valid user and verify the extra 
        information provided."""

        api = ApiHandler()

        favorites = query_admin("favorites")["favorites"]

        # Check to verify favorites.
        self.assertTrue(len(favorites) > 0,
                        "Must be at least one favorited post.")
        
        favorite_author = favorites[0]["user"]
        favorite_post = favorites[0]["post"]
        
        url = self.base_urls[yp.API_GET] # XXX: returns array of one.
        resp = api.fetch(url, {"id" : favorite_post})        
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)[0]

        author_of_post = data["author"]
        
        url = self.base_urls[yp.API_QUERY]
        resp = api.fetch(url, {"author" : author_of_post,
                               "user" : favorite_author})        
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)

        # This should return the entry we're looking for.
        found = False
        for post in data:
            #print post["id"]
            if post["id"] == favorite_post:
                found = True
                self.assertTrue(post["favorite_of_user"] == True,
                                "Post should indicate that it's been favorited by user")
                break

        self.assertTrue(found, "Entry must have been returned by author query.")

    def test_valid_query_optional_since(self):
        """Call snapshot/query with a valid since and verify it basically just
        does a refresh.
        
        I need to implement a test where there are results and when there are
        none new.  So, we'll have to create a boring post just for the test.
        
        But you cannot REALLY guarantee that the refresh won't be a complete
        refresh; so we basically just need to make sure the results are 
        newer."""

        # Query, then run the query again from the middle somewhere and it
        # should return a bit.
        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()
        
        resp = api.fetch(url, {"tag" : self.valid_tag})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        last_len = len(data)

        self.assertTrue(last_len > 2,
                        "Must return at least 1 entry for tag: %s." \
                            % self.valid_tag)

        newest_id = data[1]["id"]

        resp = api.fetch(url, {"tag" : self.valid_tag,
                               "since" : newest_id})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data2 = simplejson.loads(api.get_raw(resp))

        self.assertTrue(len(data2) >= 1,
                        "Must return at least 1 entry for tag: %s." \
                            % self.valid_tag)

        self.assertTrue(data[0]["id"] == data2[len(data2)-1]["id"], "Previous newest should be oldest refresh.")

    ###########################################################################
    ## --------------- snapshot/view
    ###########################################################################

    def test_invalid_view_param(self):
        """Call snapshot/view with an invalid parameter."""

        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()
        
        resp = api.fetch(url, {"yam" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_view_value(self):
        """Call snapshot/view with an invalid value."""

        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()

        resp = api.fetch(url, {"id" : 'invalid'})
        
        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_view(self):
        """Call snapshot/view with a valid value.
        
        Verifies it received the correct HTTP code and also that it received
        at least 1 KiB of data."""

        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        raw = api.get_raw(resp)

        self.assertTrue(len(raw) > 1024, "Received insufficient data")

    def test_valid_view_thumbnail(self):
        """Call snapshot/view with a valid value and thumbnail set."""

        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : self.new_post, "thumbnail" : None})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        raw = api.get_raw(resp)

        self.assertTrue(len(raw) > 1024, "Received insufficient data: %d" % len(raw))

    def test_valid_view_large(self):
        """Call snapshot/view with a valid value and large set."""

        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : self.new_post, "large" : None})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        raw = api.get_raw(resp)

        self.assertTrue(len(raw) > 1024, "Received insufficient data: %d" % len(raw))

    def test_valid_repost_view(self):
        """Call snapshot/view with a valid value; that is from a re-post.
        
        Verifies it received the correct HTTP code and also that it received
        at least 1 KiB of data."""
        
        repost_of = None
        
        # downloading this should point to the original post.
        data = query_admin("posts")
        for post in data["posts"]:
            if "repost_of" in post:
                repost_of = post["id"]
                break

        self.assertTrue(repost_of is not None, "No reposts found.")
        
        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : repost_of})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        raw = api.get_raw(resp)

        self.assertTrue(len(raw) > 1024, "Received insufficient data")

    ###########################################################################
    ## --------------- snapshot/create
    ###########################################################################

    def test_invalid_create_param(self):
        """Call snapshot/create with an invalid parameter, or one missing, 
        because currently the code just ignores extraneous input."""

        url = self.base_urls[yp.API_CREATE]
        params = {"author" : self.valid_author,
                  "tags" : "ready, set, go",
                  "code" : 98098098098} 
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_invalid_create_value_tags_toomany(self):
        """Call snapshot/create with too many tags."""

        # XXX: Both of these attempts need to use real data; or at least 
        # near-real data.

        url = self.base_urls[yp.API_CREATE]
        params = {"author" : self.valid_author,
                  "tags" : "ready, set, test, too many",
                  "data" : open("test-img/photo.jpg", "rb"),
                  "code" : 98098098098}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_invalid_create_value_tags_toolong(self):
        """Call snapshot/create with a tag that is too long."""
        
        self.assertTrue(False, "Test not implemented.")

    def test_invalid_create_value_author(self):
        """Call snapshot/create with an invalid data object, such as an invalid
        image. -- since we probably don't check.
        
        Or more interestingly, an invalid author id."""

        url = self.base_urls[yp.API_CREATE]
        params = {"author" : 'invalid',
                  "tags" : "invalid, author, test",
                  "data" : open("test-img/photo.jpg", "rb"),
                  "code" : 98098098098}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_invalid_create_value_data(self):
        """Call snapshot/create with an invalid data object, such as an invalid
        image. -- since we probably don't check.
        
        Or more interestingly, an invalid author id."""

        url = self.base_urls[yp.API_CREATE]
        params = {"author" : self.valid_author,
                  "tags" : "invalid, author, test",
                  "data" : "what-this isn't an image???",
                  "code" : 98098098098}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_valid_create(self):
        """Call snapshot/create."""

        url = self.base_urls[yp.API_CREATE]
        params = {"author" : self.valid_author,
                  "tags" : "valid, author, test",
                  "code" : 98098098098,
                  "data" : open("test-img/photo.jpg", "rb")} 
        # location is optional.

        # We should really have this return something to the caller.
        api = ApiHandler()
        resp = api.fetchmp(url, None, params)
        new_id = simplejson.loads(resp)["id"]

        post_data = grab_post(new_id)

        tags_read = ", ".join(post_data["tags"])

        self.assertTrue(str(tags_read) == params["tags"],
                        "Tags not created properly, %s != %s" \
                            % (str(tags_read), params["tags"]))

        delete_post(new_id)

    def test_valid_create_utf8(self):
        """Call snapshot/create with utf8 tags."""

        url = self.base_urls[yp.API_CREATE]
        params = {"author" : self.valid_author,
                  "tags" : "健康和幸福, author, test",
                  "code" : 98098098098,
                  "data" : open("test-img/photo.jpg", "rb")} 
        # location is optional.

        # We should really have this return something to the caller.
        api = ApiHandler()
        resp = api.fetchmp(url, None, params)
        new_id = simplejson.loads(resp)["id"]

        post_data = grab_post(new_id)

        delete_post(new_id)

#        print post_data["tags"][0]
#        print post_data["tags"][1]
#        print post_data["tags"][2]

        sent_tags = params["tags"].split(", ")
        self.assertTrue(post_data["tags"][0] == unicode(sent_tags[0], "utf-8"),
                        "Tags don't match.")
        self.assertTrue(post_data["tags"][1] == unicode(sent_tags[1], "utf-8"),
                        "Tags don't match.")
        self.assertTrue(post_data["tags"][2] == unicode(sent_tags[2], "utf-8"),
                        "Tags don't match.")

    def test_valid_create_large(self):
        """Submit a large image, it should be shrunk properly."""
        
        self.assertTrue(False, "Test not implemented")
        
        # XXX: This test isn't entirely necessarily specifically, but I would 
        # like it so that the code image.thumbnail() has something to do.

    ###########################################################################
    ## --------------- snapshot/delete
    ###########################################################################

    def test_invalid_delete_param(self):
        """Call snapshot/delete with an invalid parameter."""
        
        url = self.base_urls[yp.API_DELETE]
        api = ApiHandler()
        resp = api.fetch(url, None, {"yam" : self.new_post,
                                     "code" : 58780932341})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_delete_value(self):
        """Call snapshot/delete with an invalid value."""
        
        url = self.base_urls[yp.API_DELETE]        
        api = ApiHandler()
        resp = api.fetch(url, None, {"id" : 'invalid', "code" : 58780932341})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_delete(self):
        """Call snapshot/delete after creating a new post.  This amusingly, 
        needs for snapshot/query?author to work and snapshot/create to work."""

        api = ApiHandler()

        # set up the entry for deletion.
        count = len(query_admin("posts")["posts"])
        created_id = create_post(self.valid_author)
        new_count = len(query_admin("posts")["posts"])

        # this makes it at least one.
        self.assertTrue(new_count == count + 1, "Entry not created.")
 
        # delete the entry.
        resp = api.fetch(self.base_urls[yp.API_DELETE],
                         None,
                         {"id" : created_id, "code" : 58780932341})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_valid_delete_reply(self):
        """Call snapshot/delete after creating a reply.  This amusingly, 
        needs for snapshot/query?author to work and snapshot/create to work."""

        url = self.base_urls[yp.API_QUERY]

        api = ApiHandler()

        # add entry
        self.test_valid_reply()

        resp = api.fetch(url, {"tag" : "test"})

        # should be 1
        post_list = simplejson.loads(api.get_raw(resp))

        # this makes it at least one.
        self.assertTrue(len(post_list) == 1,
                        "Entry not created: %d." % len(post_list))
        
        reply_to = post_list[0]["reply_to"]

        url = self.base_urls[yp.API_DELETE]
        resp = api.fetch(url, None, {"id" : post_list[0]["id"],
                                     "code" : 58780932341})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        data = query_admin("posts")
        
        # This won't work shortly, as a post may have replies.  So, I'll need to
        # make sure the test_reply code picks one without...
        for post in data["posts"]:
            if post["id"] == reply_to:
                self.assertTrue(post["num_replies"] == 0, "Still has reply")

    ###########################################################################
    ## --------------- snapshot/cleanup
    ###########################################################################

    def test_cleanup(self):
        """Call snapshot/cleanup... Really just a good practice."""
        
        url = self.base_urls[yp.API_CLEANUP]
        
        api = ApiHandler()
        resp = api.fetch(url, None, {"code" : 58780932341})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    ###########################################################################
    ## --------------- snapshot/reply
    ###########################################################################

    def test_invalid_reply_param(self):
        """Call snapshot/reply with an invalid parameter, or one missing,
        because currently the code just ignores extraneous input."""

        url = self.base_urls[yp.API_REPLY]
        params = {"author" : self.valid_author,
                  "tags" : "ready, set, go",
                  "data" : open("test-img/photo.jpg", "rb"),
                  "code" : 98098098098}
        # location is optional.
        # missing reply_to
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_invalid_reply_value(self):
        """Call snapshot/reply with an invalid value, the ObjectId for the 
        reply's source message will be invalid."""

        url = self.base_urls[yp.API_REPLY]
        params = {"author" : self.valid_author,
                  "tags" : "ready, set, go",
                  "data" : open("test-img/photo.jpg", "rb"),
                  "code" : 98098098098,
                  "reply_to" : 'invalid'}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_valid_reply(self):
        """Call snapshot/reply with valid parameters."""

        data = query_admin("posts")
        post_count = len(data["posts"])
        
        self.assertTrue(post_count > 0,
                        "Insufficient data available: %d." % post_count)

        source_id = None
        
        for post in data["posts"]:
            if post["num_replies"] == 0:
                source_id = post["id"]
                break

        self.assertTrue(source_id is not None,
                        "At least one post cannot already have a reply for test_valid_delete_reply() to work.")

        url = self.base_urls[yp.API_REPLY]
        params = {"author" : self.valid_author,
                  "tags" : "valid, author, test",
                  "data" : open("test-img/photo.jpg", "rb"),
                  "code" : 98098098098,
                  "reply_to" : source_id}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        new_id = resp
        
        data = query_admin("posts")
        new_count = len(data["posts"])
        
        self.assertTrue(post_count + 1 == new_count, "Post was not created.")
        
        for posts in data["posts"]:
            if posts["id"] == source_id:
                self.assertTrue(posts["num_replies"] == 1,
                                "Post does not indicate reply.")
        
        # XXX: num_replies should be decremented upon delete.
        
        #posts = [str(post["id"]) for post in data["posts"]]
        #self.assertTrue(new_id in posts, "%s not found in %s" % (new_id, str(posts)))

    ###########################################################################
    ## --------------- snapshot/home
    ###########################################################################

    def test_invalid_home_param(self):
        """Call snapshot/home with an invalid parameter."""
        
        url = self.base_urls[yp.API_HOME]        
        api = ApiHandler()
        
        resp = api.fetch(url, {"yam" : self.valid_author})
        
        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_home_value(self):
        """Call snapshot/home with an invalid value."""
        
        url = self.base_urls[yp.API_HOME]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_valid_home(self):
        """Call snapshot/home with valid input."""

        watches = query_admin("watches")["watches"]

        self.assertTrue(len(watches) > 0,
                        "Must be at least one watch in place.")

        author = watches[0]["author"]

        url = self.base_urls[yp.API_HOME]
        api = ApiHandler()

        resp = api.fetch(url, {"id" : author})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)

        self.assertTrue(len(data) > 0, "Must return at least 1 entry.")

    def test_valid_home_no_watches(self):
        """Call snapshot/home with valid input, however, pick a user who is
        watching nobody."""
        
        data = query_admin()
        users = [user["id"] for user in data["users"]]
        watches = [watch["author"] for watch in data["watches"]]
        
        useful_author = None
        
        for user in users:
            if user not in watches:
                useful_author = user
        
        self.assertTrue(useful_author is not None,
                        "An author must exist who does not follow anyone.")
        
        url = self.base_urls[yp.API_HOME]
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : useful_author})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) == 0, "Must return at least 1 entry.")

    ###########################################################################
    ## --------------- snapshot/favorite
    ###########################################################################

    def test_invalid_favorite_param(self):
        """Call snapshot/favorite which an invalid parameter."""
        
        url = self.base_urls[yp.API_FAVORITE]
        api = ApiHandler()
        
        resp = api.fetch(url, None, {"yo" : self.valid_author,
                                     "post" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_favorite_values(self):
        """Call snapshot/favorite with an invalid post id."""
        
        url = self.base_urls[yp.API_FAVORITE]
        api = ApiHandler()

        resp = api.fetch(url, None, {"user" : self.valid_author,
                                     "post" : 'notpost'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_favorite_duplicate(self):
        """Call snapshot/favorite with a duplicate entry."""

        url = self.base_urls[yp.API_FAVORITE]
        api = ApiHandler()

        data = query_admin("favorites")
        enjoy_count = len(data["favorites"])

        self.assertTrue(len(data["favorites"]) > 0,
                        "Cannot create duplicates if there are no posts marked as enjoyed")

        useful_author = data["favorites"][0]["user"]
        useful_post = data["favorites"][0]["post"]

        resp = api.fetch(url, None, {"user" : useful_author,
                                     "post" : useful_post})

        
        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        new_count = len(query_admin("favorites")["favorites"])

        self.assertTrue(enjoy_count == new_count,
                        "Entry count should not have increased.")

    def test_valid_favorite(self):
        """Call snapshot/favorite with valid information."""

        api = ApiHandler()

        enjoy_count = len(query_admin("favorites")["favorites"])

        resp = api.fetch(self.base_urls[yp.API_FAVORITE],
                         None,
                         {"user" : self.valid_author, "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        new_enjoys = len(query_admin("favorites")["favorites"])

        self.assertTrue(enjoy_count + 1 == new_enjoys,
                        "Enjoy Call Unsuccessful")

    ###########################################################################
    ## --------------- snapshot/unfavorite
    ###########################################################################

    def test_invalid_unfavorite_param(self):
        """Call snapshot/unfavorite with an invalid parameter."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_UNFAVORITE],
                         None,
                         {"yo" : self.valid_author, "post" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_unfavorite_value(self):
        """Call snapshot/unfavorite with an invalid post id."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_UNFAVORITE],
                         None,
                         {"user" : self.valid_author, "post" : 'notpost'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_unfavorite(self):
        """Call snapshot/unfavorite with valid stuff."""

        api = ApiHandler()

        # Favorite a post.
        resp = api.fetch(self.base_urls[yp.API_FAVORITE],
                         None,
                         {"user" : self.valid_author, "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        enjoy_count = len(query_admin("favorites")["favorites"])
        
        # Unfavorite that post.
        resp = api.fetch(self.base_urls[yp.API_UNFAVORITE],
                         None,
                         {"user" : self.valid_author, "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        enjoy_count2 = len(query_admin("favorites")["favorites"])
        
        self.assertTrue(enjoy_count2 == enjoy_count - 1,
                        "Favorite count not changed.")

    ###########################################################################
    ## --------------- snapshot/report
    ###########################################################################

    def test_invalid_report_param(self):
        """Call snapshot/report with an invalid parameter."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_REPORT],
                         None,
                         {"yo" : self.valid_author, "post" : self.new_post})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_report_value(self):
        """Call snapshot/report with an invalid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_REPORT],
                         None,
                         {"user" : self.valid_author, "post" : 'notpost'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_report(self):
        """Call snapshot/report with valid stuff."""

        api = ApiHandler()

        enjoy_count = len(query_admin("reports")["reports"])

        resp = api.fetch(self.base_urls[yp.API_REPORT],
                         None,
                         {"user" : self.valid_author, "post" : self.new_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        post_data = grab_post(self.new_post)

        self.assertTrue(post_data["flagged"] == 1,
                        "Flagged was not updated.")

        new_enjoys = len(query_admin("reports")["reports"])

        self.assertTrue(enjoy_count + 1 == new_enjoys,
                        "Report Call Unsuccessful")

    ###########################################################################
    ## --------------- snapshot/repost
    ###########################################################################

    def test_invalid_repost_param(self):
        """Call snapshot/repost with an invalid parameter, or one missing,
        because currently the code just ignores extraneous input."""

        url = self.base_urls[yp.API_REPOST]
        params = {"author" : self.valid_author,
                  "tags" : "ready, set, go",
                  "code" : 98098098098}
        # location is optional.
        # missing repost_of
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_invalid_repost_value(self):
        """Call snapshot/repost with an invalid value, the ObjectId for the 
        reply's source message will be invalid."""

        url = self.base_urls[yp.API_REPOST]
        params = {"author" : self.valid_author,
                  "tags" : "ready, set, go",
                  "code" : 98098098098,
                  "reply_to" : 'invalid'}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_invalid_repost_value_identical_tags(self):
        """Call snapshot/repost with an invalid value, the tags are identical
        to the original post's; this is not allowed."""

        url = self.base_urls[yp.API_REPOST]
        data = query_admin("posts")

        self.assertTrue(len(data["posts"]) > 0,
                        "There must be at least one post.")

        original_post = data["posts"][0]
        
        params = {"author" : self.valid_author,
                  "tags" : ",".join(original_post["tags"]),
                  "code" : 98098098098,
                  "reply_to" : original_post["id"]}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        self.assertTrue(resp == "HTTP Error 400: Bad Request",
                        "Invalid response: %s" % resp)

    def test_valid_repost(self):
        """Call snapshot/repost with valid parameters."""

        data = query_admin("posts")
        post_count = len(data["posts"])
        
        self.assertTrue(post_count > 0,
                        "Insufficient data available: %d." % post_count)

        source_id = data["posts"][0]["id"]
        num_reposts_start = data["posts"][0]["num_reposts"]

        url = self.base_urls[yp.API_REPOST]
        params = {"author" : self.valid_author,
                  "tags" : "valid, author, test",
                  "code" : 98098098098,
                  "repost_of" : source_id}
        # location is optional.
        
        api = ApiHandler()
        resp = api.fetchmp(url, None, params) # doesn't attach data...
        new_id = resp
        
        data = query_admin("posts")
        new_count = len(data["posts"])
        
        self.assertTrue(post_count + 1 == new_count, "Post was not created.")
        
        for post in data["posts"]:
            if post["id"] == source_id:
                self.assertTrue(post["num_reposts"] == num_reposts_start + 1,
                                "Post does not indicate repost.")
        
        # XXX: num_reposts should be decremented upon delete.
        
        #posts = [str(post["id"]) for post in data["posts"]]
        #self.assertTrue(new_id in posts, "%s not found in %s" % (new_id, str(posts)))

    ###########################################################################
    ## --------------- snapshot/public
    ###########################################################################

    def test_public(self):
        """Calls snapshot/public as nobody in particular."""

        url = self.base_urls[yp.API_PUBLIC]        
        api = ApiHandler()
        resp = api.fetch(url, None)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 1, "Must return at least 2 entries.")

    def test_public_asuser(self):
        """Calls snapshot/public as user."""

        url = self.base_urls[yp.API_PUBLIC]        
        api = ApiHandler()
        resp = api.fetch(url, {"user" : self.valid_author})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 1, "Must return at least 2 entries.")
        
        # XXX: Should verify the posts have the boolean fields.

class TestUserFunctions(unittest.TestCase):
    """."""

    base_urls = \
        {
            yp.API_AUTHORIZE :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_AUTHORIZE),
            yp.API_CREATE :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_CREATE),
            yp.API_DELETE :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_DELETE),
            yp.API_FAVORITED :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_FAVORITED),
            yp.API_GET :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_GET),
            yp.API_LEAVE :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_LEAVE),
            yp.API_LOGIN :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_LOGIN),
            yp.API_JOIN :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_JOIN),
            yp.API_QUERY :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_QUERY),
            yp.API_UPDATE :
                "%s/%s/%s " % (yp.BASE_URL, yp.USER_URL, yp.API_UPDATE),
            yp.API_WATCH : 
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_WATCH),
            yp.API_UNAUTHORIZE :
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_UNAUTHORIZE),
            yp.API_UNWATCH : 
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_UNWATCH),
            yp.API_VIEW:
                "%s/%s/%s" % (yp.BASE_URL, yp.USER_URL, yp.API_VIEW),
        }
        
    valid_author = []
    valid_screen_name = []
    fresh_user = {}

    def setUp(self):
        """Call before every test case."""
        
        data = query_admin()
        
        if len(data["users"]) < 2:
            raise Exception("Insufficient Users Pre-built")

        # XXX: Later we'll have to have a few users in mind because someone may
        # legitimately set their screen name to something that starts with user.
        found = 0
        for user in data["users"]:
            if user["screen_name"].startswith("user"):
                self.valid_author.append(user["id"])
                self.valid_screen_name.append(user["screen_name"])
                found += 1
            if found == 2:
                break
        
        self.valid_tag = data["posts"][0]["tags"][0]
        self.valid_tag2 = None
        
        for post in data["posts"]:
            if len(post["tags"]) > 1:
                self.valid_tag2 = post["tags"][1]
        
        if self.valid_tag2 is None:
            raise Exception("Insufficient Tags within Posts")
        
        self.fresh_user[0] = create_user("testguy_fresh")
        self.fresh_user[1] = create_user("testguy_fresh2")
    
    def tearDown(self):
        """Call after every test case."""

        data = query_admin()

        url = self.base_urls[yp.API_DELETE]
        api = ApiHandler()
        
        
        
        # delete test users
        # XXX: This will be a problem if there are any users whose screen name
        # starts with test.
        for user in data["users"]:
            if user["screen_name"].startswith("test"):
                api.fetch(url, None, {"id" : user["id"], "code" : 58780932341})

        url = self.base_urls[yp.API_UNWATCH]
        for watch in data["watches"]:
            if watch["author"] == self.valid_author[0]:
                api.fetch(url,
                          None,
                          {"author" : self.valid_author[0],
                           "watched" : watch["watched"],
                           "code" : 98098098098})

    ###########################################################################
    # --------------- user/authorize
    ###########################################################################
    
    def test_invalid_authorize_param(self):
        """Call user/authorize with an invalid parameter."""

        api = ApiHandler()
 
        resp = api.fetch(self.base_urls[yp.API_AUTHORIZE],
                         None,
                         {"yam" : self.fresh_user[0],
                          "authorizer" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_authorize_value(self):
        """Call user/authorize with an invalid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_AUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_authorize(self):
        """Call user/authorize for a user who is already authorized, should
        return a safe 400."""

        self.assertTrue(False, "Test not yet implemented.")

    def test_valid_authorize(self):
        """Call user/authorize with valid parameters.  It may make sense to
        create fake users for all the user stuff so that the user we're 
        authorizing wasn't previously authorized and isn't a stranger."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_AUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : self.fresh_user[1]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    ###########################################################################
    # --------------- user/unauthorize
    ###########################################################################

    def test_invalid_unauthorize_param(self):
        """Call user/unauthorize with an invalid parameter."""

        api = ApiHandler()
 
        resp = api.fetch(self.base_urls[yp.API_UNAUTHORIZE],
                         None,
                         {"yam" : self.fresh_user[0],
                          "authorizer" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_unauthorize_value(self):
        """Call user/unauthorize with an invalid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_UNAUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_unauthorize(self):
        """Call user/unauthorize with a user who was not authorized.  Should 
        return 200..."""

        api = ApiHandler()

        # unauthorize guy you never authorized.
        resp = api.fetch(self.base_urls[yp.API_UNAUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : self.fresh_user[1]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_unauthorize(self):
        """Call user/unauthorize with valid parameters."""

        api = ApiHandler()

        # authorize guy you need to unauthorize.
        resp = api.fetch(self.base_urls[yp.API_AUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : self.fresh_user[1]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # unauthorize guy you just authorized.
        resp = api.fetch(self.base_urls[yp.API_UNAUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : self.fresh_user[1]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    ###########################################################################
    # --------------- user/get
    ###########################################################################

    def test_invalid_get_param(self):
        """Call user/get with an invalid parameter."""

        url = self.base_urls[yp.API_GET]        
        api = ApiHandler()
        resp = api.fetch(url, {"yaw" : self.valid_author[0]})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_get_value(self):
        """Call user/get with an inavlid value."""

        url = self.base_urls[yp.API_GET]        
        api = ApiHandler()
        
        resp = api.fetch(url, {"id" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_get(self):
        """Call user/get with a valid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_GET],
                         {"id" : self.valid_author[0]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(data["id"] == self.valid_author[0],
                        "Data returned does not match.")

    def test_valid_get_full(self):
        """Call user/get with the full parameter."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_GET],
                         {"id" : self.valid_author[0], "full" : "true"})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(data["id"] == self.valid_author[0],
                        "Data returned does not match.")

        self.assertTrue("favorites" in data,
                        "Data returned must include favorites list.")

    def test_valid_get_by_screen_name(self):
        """Call user/get with a valid value, as a screen_name."""
        
        users = query_admin("users")["users"]
        user = users[0]

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_GET],
                         {"screen_name" : user["screen_name"]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(data["id"] == user["id"],
                        "Data returned does not match.")        

    ###########################################################################
    # --------------- POST user/get
    ###########################################################################
    
    def test_invalid_postget_param(self):
        """Call POST user/get with an invalid parameter."""

        url = self.base_urls[yp.API_GET]        
        api = ApiHandler()
        resp = api.fetch(url, None, {"yaw" : self.valid_author[0]})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_postget_value(self):
        """Call POST user/get with an inavlid value."""

        url = self.base_urls[yp.API_GET]        
        api = ApiHandler()
        
        resp = api.fetch(url, None, {"id" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_postget(self):
        """Call user/get with a valid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_GET],
                         None,
                         {"id" : self.fresh_user[0],
                          "requester" : self.fresh_user[1]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(data["id"] == self.fresh_user[0],
                        "Data returned does not match.")
        
        self.assertTrue("authorized" in data, "Data returned left out key element")
    
    def test_valid_postget_self(self):
        """Call POST user/get on yourself."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_GET],
                         None,
                         {"id" : self.fresh_user[0],
                          "requester" : self.fresh_user[0]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(data["id"] == self.fresh_user[0],
                        "Data returned does not match.")
        
        self.assertTrue("authorized" in data,
                        "Data returned left out key element")
        
        self.assertTrue(data["authorized"] == True,
                        "You should be authorized for yourself: %s" % str(data))
    
    def test_valid_postget_authorized(self):
        """Call POST user/get on a user who has authorized you to see their
        comments."""

        # user[1] authorizes user[0] to see comments
        # user[0] requests user[1] information
        # authorized == True

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_AUTHORIZE],
                         None,
                         {"authorized" : self.fresh_user[0],
                          "authorizer" : self.fresh_user[1]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # I am user[0], give me information about user[1].
        resp = api.fetch(self.base_urls[yp.API_GET],
                         None,
                         {"id"        : self.fresh_user[1],
                          "requester" : self.fresh_user[0]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(data["id"] == self.fresh_user[1],
                        "Data returned does not match.")
        
        self.assertTrue("authorized" in data,
                        "Data returned left out key element")
        
        self.assertTrue(data["authorized"] == True,
                        "You should be authorized for user: %s" % str(data))

        self.assertTrue(data["authorized_back"] == False,
                        "This user should not be authorized to read yours.")

    ###########################################################################
    #### user/create
    ###########################################################################

    def test_invalid_create_param(self):
        """Call user/create with an invalid parameter, or one missing, 
        because currently the code just ignores extraneous input."""

        api = ApiHandler()

        # missing screen_name which is required.
        params = {"display_name" : "testguy",
                  "code" : 98098098098,
                  "email" : "user@whatever.com"}

        resp = api.fetch(self.base_urls[yp.API_CREATE], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_create_value(self):
        """Call user/create with an invalid data object, such as an invalid
        image. -- since we probably don't check."""

        api = ApiHandler()
        
        # missing screen_name which is required.
        params = {"realish_name" : "testguy",
                  "display_name" : "testguy1",
                  "code" : 17,
                  "email" : "user@whatever.com"}

        resp = api.fetch(self.base_urls[yp.API_CREATE], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_create_duplicate(self):
        """Call user/create with everything valid, but a duplicate 
        screen_name."""

        data = query_admin("users")
        users = data["users"]

        self.assertTrue(len(users) > 0, "Must be at least one user.")

        screen_name = users[0]["screen_name"]

        api = ApiHandler()
        
        # missing screen_name which is required.
        params = {"realish_name" : "testguy",
                  "display_name" : screen_name, # display_name is dropped to lowercase and checked as screen_name
                  "code" : 98098098098,
                  "email" : "user@whatever.com"}

        resp = api.fetch(self.base_urls[yp.API_CREATE], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_create(self):
        """Call user/create with valid parameters."""

        api = ApiHandler()

        post_count = len(query_admin("users")["users"])

        # missing screen_name which is required.
        params = {"realish_name" : "testguy1",
                  "display_name" : "testguy1",
                  "code" : 98098098098,
                  "email" : "user@whatever.com"}

        resp = api.fetch(self.base_urls[yp.API_CREATE], None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        new_count = len(query_admin("users")["users"])

        self.assertTrue(post_count + 1 == new_count, "Did not create user.")

    ###########################################################################
    #### user/delete
    ###########################################################################

    def test_invalid_delete_param(self):
        """Call user/delete with an invalid parameter."""

        params = {"yam" : self.valid_author[0], "code" : 58780932341}
         
        api = ApiHandler()
        resp = api.fetch(self.base_urls[yp.API_DELETE], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_delete_value(self):
        """Call user/delete with an invalid value."""

        api = ApiHandler()
        resp = api.fetch(self.base_urls[yp.API_DELETE],
                         None,
                         {"id" : 'invalid', "code" : 58780932341})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_valid_delete(self):
        """Call user/delete after creating a new post.  This amusingly, 
        needs for snapshot/query?author to work and snapshot/create to work."""

        self.test_valid_create()
        data = query_admin("users")
        user_count = len(data["users"])
        delete_id = None
        
        for user in data["users"]:
            if user["screen_name"] == "testguy1":
                delete_id = user["id"]
                break

        self.assertTrue(delete_id is not None, "delete_id should be a value.")

        url = self.base_urls[yp.API_DELETE]
        api = ApiHandler()
        resp = api.fetch(url, None, {"id" : delete_id, "code" : 58780932341})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
 
        new_count = len(query_admin("users")["users"])
        
        self.assertTrue(user_count - 1 == new_count, "User was not deleted.")

    ###########################################################################
    #### user/watch
    ###########################################################################

    def test_invalid_watch_param(self):
        """Call user/watch with an invalid parameter."""

        api = ApiHandler()
        params = {"yam" : self.valid_author[0],
                  "watched" : self.valid_author[1],
                  "code" : 98098098098}
        
        resp = api.fetch(self.base_urls[yp.API_WATCH], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_watch_value(self):
        """Call user/watch with an invalid value."""

        api = ApiHandler()
        params = {"author" : 'invalid',
                  "watched" : self.valid_author[1],
                  "code" : 98098098098}
        
        resp = api.fetch(self.base_urls[yp.API_WATCH], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_watch(self):
        """Call user/watch with valid parameters."""

        # get current watching/watched counts
        data = query_admin("users")
        counts = {self.valid_author[0] : 0, self.valid_author[1] : 0}
        
        for user in data["users"]:
            if self.valid_author[0] == user["id"]:
                counts[self.valid_author[0]] = user["watching"]
            if self.valid_author[1] == user["id"]:
                counts[self.valid_author[1]] = user["watched"]

        api = ApiHandler()
        params = {"author" : self.valid_author[0],
                  "watched" : self.valid_author[1],
                  "code" : 98098098098}
        
        resp = api.fetch(self.base_urls[yp.API_WATCH], None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        # the object created here is deleted by the teardown()
        data = query_admin("users")
        
        for user in data["users"]:
            if self.valid_author[0] == user["id"]:
                prev_watching = counts[self.valid_author[0]]
                self.assertTrue(prev_watching + 1 == user["watching"],
                                "Watching value did not increment properly.")
            if self.valid_author[1] == user["id"]:
                prev_watched = counts[self.valid_author[1]]
                self.assertTrue(prev_watched + 1 == user["watched"],
                                "Watched value did not increment properly.")

        data = query_admin("watches")

        found = False
        for watch in data["watches"]:
            if watch["author"] == self.valid_author[0] \
                and watch["watched"] == self.valid_author[1]:
                found = True

        self.assertTrue(found, "Watch entry was not added.")

    ###########################################################################
    #### user/unwatch
    ###########################################################################

    def test_invalid_unwatch_param(self):
        """Call user/unwatch with an invalid parameter."""

        api = ApiHandler()
        params = {"author" : 'invalid',
                  "watched" : self.valid_author[1],
                  "code" : 98098098098}
        
        resp = api.fetch(self.base_urls[yp.API_UNWATCH], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_unwatch_value(self):
        """Call user/unwatch with an invalid value."""

        api = ApiHandler()
        params = {"author" : 'invalid',
                  "watched" : self.valid_author[1],
                  "code" : 98098098098}
        
        resp = api.fetch(self.base_urls[yp.API_UNWATCH], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_unwatch(self):
        """Call user/unwatch with valid parameters."""

        # get current watching/watched counts
        data = query_admin("users")
        counts = {self.valid_author[0] : 0, self.valid_author[1] : 0}
        
        for user in data["users"]:
            if self.valid_author[0] == user["id"]:
                counts[self.valid_author[0]] = user["watching"]
            if self.valid_author[1] == user["id"]:
                counts[self.valid_author[1]] = user["watched"]

        # set up the test -- this will increment their values by 1, as verified
        # by the test being called.
        self.test_valid_watch()

        url = self.base_urls[yp.API_UNWATCH]
        api = ApiHandler()
        params = {"author" : self.valid_author[0],
                  "watched" : self.valid_author[1],
                  "code" : 98098098098}
        
        resp = api.fetch(url, None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # Verify the values decremented.
        data = query_admin("users")
        
        for user in data["users"]:
            if self.valid_author[0] == user["id"]:
                prev_watching = counts[self.valid_author[0]]
                self.assertTrue(prev_watching == user["watching"],
                                "Watching value did not decrement properly."
                                + "(%d != %d)" % (prev_watching, user["watching"]))
                
            if self.valid_author[1] == user["id"]:
                prev_watched = counts[self.valid_author[1]]
                self.assertTrue(prev_watched == user["watched"],
                                "Watched value did not decrement properly."
                                + "(%d != %d)" % (prev_watching, user["watched"]))

    ###########################################################################
    # --------------- user/login
    ###########################################################################
    
    def test_invalid_login_param(self):
        """Call user/login with an invalid parameter."""

        api = ApiHandler()
        resp = api.fetch(self.base_urls[yp.API_LOGIN],
                         {"yaw" : self.valid_author[0]})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_login_value(self):
        """Call user/login with an invalid value."""
         
        api = ApiHandler()
        
        resp = api.fetch(self.base_urls[yp.API_LOGIN],
                         {"screen_name" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
    def test_valid_login(self):
        """Call user/login with a valid value."""

        api = ApiHandler()
        
        resp = api.fetch(self.base_urls[yp.API_LOGIN],
                         {"screen_name" : self.valid_screen_name[0]})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))
        
        self.assertTrue(str(data["id"]) == self.valid_author[0],
                        "Return Value Unexpected")

    ###########################################################################
    # --------------- user/query
    ###########################################################################

    def test_invalid_query_param(self):
        """Call user/query with an invalid query parameter."""
 
        api = ApiHandler()
        
        resp = api.fetch(self.base_urls[yp.API_QUERY],
                         {"yam" : self.valid_author[0]})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_invalid_query_value(self):
        """Call user/query with a valid user, but an invalid query."""

        api = ApiHandler()
        
        resp = api.fetch(self.base_urls[yp.API_QUERY],
                         {"id" : self.valid_author[0], "query" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # querying for tags cannot really get an invalid string value.

    def test_valid_query_community(self):
        """Call user/query with a valid user, to retrieve their communities."""
        
        communities = query_admin("communities")["communities"]

        self.assertTrue(len(communities) > 0,
                        "Must be at least one person in one community" + 
                        " for this test to guarantee to work.")

        community = communities[0]["user"]

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_QUERY],
                         {"id" : community, "query" : "community"})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
 
        data = simplejson.loads(api.get_raw(resp))

        self.assertTrue(len(data) > 0, "Must return at least 1 entry...")
        
        # verify the community list is correct.

    def test_valid_query_watchlist(self):
        """Call user/query with a valid user, to retrieve their watchlist."""

        data = query_admin("watches")["watches"]
        
        self.assertTrue(len(data) > 0,
                        "At least one user must be watching another " + 
                        "for this test to be valid.")

        temp_author = data[0]["author"]
        temp_author_count = 0
        
        for item in data:
            if temp_author == item["author"]:
                temp_author_count += 1

        url = self.base_urls[yp.API_QUERY]
        api = ApiHandler()

        resp = api.fetch(url, {"id" : temp_author, "query" : "watchlist"})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(len(data) > 0, "Must return at least 1 entry...")

        self.assertTrue(len(data) == temp_author_count,
                        "Entry counts don't match.")

    def test_valid_query_favorites(self):
        """Call user/query with a valid user, to retrieve their favorites."""
        
        data = query_admin("favorites")["favorites"]
        
        self.assertTrue(len(data) > 0,
                        "At least one user must favorite a " +
                        "post for this test to be valid.")
        
        temp_author = data[0]["user"]
        temp_author_count = 0
        
        for item in data:
            if temp_author == item["user"]:
                temp_author_count += 1

        api = ApiHandler()
        
        resp = api.fetch(self.base_urls[yp.API_QUERY],
                         {"id" : temp_author, "query" : "favorites"})
        
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = simplejson.loads(api.get_raw(resp))
        
        self.assertTrue(len(data) > 0, "Must return at least 1 entry...")

        self.assertTrue(len(data) == temp_author_count,
                        "Entry counts don't match.")

    ###########################################################################
    # --------------- user/join
    ###########################################################################
    
    def test_invalid_join_param(self):
        """Call user/join with an invalid parameter."""

        api = ApiHandler()
        params = {"yam" : self.valid_author[0],
                  "community" : ",".join([self.valid_tag, self.valid_tag2])}
        
        resp = api.fetch(self.base_urls[yp.API_JOIN], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_join_value(self):
        """Call user/join with an invalid value."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_JOIN],
                         None,
                         {"user" : self.fresh_user[0],
                          "community" : "one, two, three, four"})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # XXX: invalid join value. there are variations, such as having three
        # tags, etc.

    def test_invalid_join_value_tags(self):
        """Call user/join with the same values for the community."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_JOIN],
                         None,
                         {"user" : self.fresh_user[0],
                          "community" : "comm, comm"})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
    
    def test_valid_join(self):
        """Call user/join with valid information."""

        api = ApiHandler()
        community = ",".join([self.valid_tag, self.valid_tag2])

        resp = api.fetch(self.base_urls[yp.API_JOIN],
                         None,
                         {"user" : self.fresh_user[0],
                          "community" : community})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        resp = api.fetch(self.base_urls[yp.API_LEAVE],
                         None,
                         {"user" : self.fresh_user[0], 
                          "community" : community})

    ###########################################################################
    # --------------- user/leave
    ###########################################################################

    def test_invalid_leave_param(self):
        """Call user/leave with an invalid parameter."""

        api = ApiHandler()
        params = {"yam" : self.valid_author[0],
                  "community" : ",".join([self.valid_tag, self.valid_tag2])}
        
        resp = api.fetch(self.base_urls[yp.API_LEAVE], None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_leave_value(self):
        """Call user/leave with an invalid value -- they can only leave a 
        community they've joined at some point."""

        api = ApiHandler()

        resp = api.fetch(self.base_urls[yp.API_LEAVE],
                         None,
                         {"user" : self.valid_author[0],
                          "community" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        # XXX: invalid join value. there are variations, such as having three
        # tags, etc.

    def test_valid_leave(self):
        """Call user/leave with valid information."""

        api = ApiHandler()
        community = ["communitya", "communityb"]

        url = self.base_urls[yp.API_JOIN]
        resp = api.fetch(url, None, {"user" : self.valid_author[0],
                                     "community" : ",".join(community)})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        data = query_admin("communities")["communities"]

        self.assertTrue(len(data),
                        "Must be at least one user in one community")

        url = self.base_urls[yp.API_LEAVE]
        resp = api.fetch(url, None, {"user" : self.valid_author[0],
                                     "community" : ",".join(community)})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    ###########################################################################
    # --------------- user/favorited
    ###########################################################################

    def test_invalid_favorited_param(self):
        """Call user/favorited with an invalid parameter --- just returns 
        False"""

        url = self.base_urls[yp.API_FAVORITED]
        api = ApiHandler()

        resp = api.fetch(url, {"user" : self.valid_author[0],
                               "yoyo" : 'invalid'})
        
        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(data["value"] == False, "Should have returned false.")

    def test_invalid_favorited_value(self):
        """Call user/favorited with an invalid value --- still returns 200."""

        url = self.base_urls[yp.API_FAVORITED]
        api = ApiHandler()

        resp = api.fetch(url, {"user" : self.valid_author[0],
                               "post" : 'invalid'})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)
        
        self.assertTrue(data["value"] == False, "Should have returned false.")

    def test_valid_favorited(self):
        """Call user/favorited with invalid values (indicating this user has 
        marked that post as enjoyed."""

        url = self.base_urls[yp.API_FAVORITED]
        api = ApiHandler()

        enjoyed_data = query_admin("favorites")["favorites"]
        
        self.assertTrue(len(enjoyed_data) > 0,
                        "Must be at least one favorited post for testing.")

        valid_user = enjoyed_data[0]["user"]
        valid_post = enjoyed_data[0]["post"]

        resp = api.fetch(url, {"user" : valid_user, "post" : valid_post})

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        json = api.get_raw(resp)
        data = simplejson.loads(json)

        self.assertTrue(data["value"] == True, "Should have returned false.")

    ###########################################################################
    # --------------- user/view
    ###########################################################################

    def test_invalid_view_param(self):
        """Call user/view with an invalid parameter."""

        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()
        
        resp = api.fetch(url, {"yam" : self.valid_author[0]})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)    

    def test_invalid_view_value(self):
        """Call user/view with an invalid value for user id."""
        
        url = self.base_urls[yp.API_VIEW]
        api = ApiHandler()

        resp = api.fetch(url, {"id" : 'invalid'})
        
        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_valid_view(self):
        """Call user/view on a user with an avatar..."""
        
        self.assertTrue(False, "Test not implemented.")

    ###########################################################################
    # --------------- user/update
    ###########################################################################

    def test_invalid_update_param(self):
        """Call user/update with an invalid parameter.  The valid ones are:
        valid keys: screen_name, display_name, bio, home, location."""

        starting_user = grab_user(self.valid_author[0])

        url = self.base_urls[yp.API_UPDATE]
        api = ApiHandler()

        resp = api.fetch(url, None, {"invalid" : 'invalid'})

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

    def test_invalid_update_value(self):
        """Call user/update with invalid values -- hm... what is inavlid in 
        terms of screen_name, display_name, bio, home, location -- maybe too
        long."""

        url = self.base_urls[yp.API_UPDATE]
        api = ApiHandler()

        self.assertTrue(False, "Test not implemented.")
    
    def test_invalid_update_value_duplicate_screenname(self):
        """Call user/update with an invalid value: someone else's 
        screen_name."""

        url = self.base_urls[yp.API_UPDATE]
        api = ApiHandler()
        
        self.assertTrue(False, "Test not implemented.")

    def test_invalid_update_value_badimage(self):
        """Call user/update with an inavlid image value."""

        # Create a user for this test.
        user_identifier = create_user("testguy_update")

        url = self.base_urls[yp.API_UPDATE]
        api = ApiHandler()

        # Test update: avatar with string!
        params = {"avatar" : 'Joe Test Blah', "user" : user_identifier}
        
        resp = api.fetch(url, None, params)

        self.assertTrue(400 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        # Delete the user from this test.
        delete_user(user_identifier)

    def test_valid_update_avatar(self):
        """Call user/update with a valid image for an avatar."""

        user_identifier = self.valid_author[0]

        url = self.base_urls[yp.API_UPDATE]
        api = ApiHandler()

        # Test update: avatar with valid value
        resp = api.fetchmp(url,
                           None,
                           {"avatar" : open("test-img/photo.jpg", "rb"),
                            "user" : user_identifier})

        # on success this returns only a 200 code, but no information.
        self.assertTrue("400" not in resp,
                        "Received an invalid code: %s" % resp)

    def test_valid_update(self):
        """Call user/update with each of the things and make sure they 
        changed."""

        # Create a user for this test.
        user_identifier = create_user("testguy_update")

        url = self.base_urls[yp.API_UPDATE]
        api = ApiHandler()

        # Test update: realish_name
        params = {"realish_name" : 'Joe Test Blah', "user" : user_identifier}
        
        resp = api.fetch(url, None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        updated_user = grab_user(user_identifier)

        self.assertTrue(updated_user["realish_name"] == params["realish_name"],
                        "The display_name value should have changed.")

        # Test update: display_name/screen_name
        params = {"display_name" : 'NewTestName', "user" : user_identifier}
        
        resp = api.fetch(url, None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        updated_user = grab_user(user_identifier)

        self.assertTrue(updated_user["display_name"] == params["display_name"],
                        "The display_name value should have changed.")

        self.assertTrue(updated_user["screen_name"] == params["display_name"].lower(),
                        "The screen_name value should have changed.")

        # Test update: bio
        params = {"bio" : 'New Bio Info', "user" : user_identifier}

        resp = api.fetch(url, None, params)

        self.assertTrue(
                        200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        updated_user = grab_user(user_identifier)

        self.assertTrue(updated_user["bio"] == params["bio"],
                        "The bio value should have changed.")

        # Test update: home
        params = {"home" : 'New Home Info', "user" : user_identifier}

        resp = api.fetch(url, None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)

        updated_user = grab_user(user_identifier)

        self.assertTrue(updated_user["home"] == params["home"],
                        "The home value should have changed.")

        # Test update: location
        params = {"location" : 'New Location Info', "user" : user_identifier}

        resp = api.fetch(url, None, params)

        self.assertTrue(200 == resp.code,
                        "Received an invalid code: %d" % resp.code)
        
        updated_user = grab_user(user_identifier)

        self.assertTrue(updated_user["location"] == params["location"],
                        "The location value should have changed.")

        # Add any other update-able members here.

        # Delete the user from this test.
        delete_user(user_identifier)

class TestPyLibFunctions(unittest.TestCase):
    """The goal of these tests are to handle unittesting of the python 
    library."""
    
    def setUp(self):
        """Call before every test case."""
        pass
    
    def tearDown(self):
        """Call after every test case."""
        pass

def main():
    """Run through tests over the network, versus tests run locally."""
    
    sys.exit(0)

if __name__ == "__main__":
    unittest.main()
