'''A library that provides a Python interface to the Test HyperionStorm API

So much to do; writing some code based on python-twitter; while not being 
directly copied.'''

__author__ = 'meh@hyperionstorm.com'
__version__ = '0.1'

import json as simplejson
import urllib
import urllib2

BASE_URL = 'http://api.hyperionstorm.com'
POST_URL = 'snapshot'
USER_URL = 'user'

API_ADMIN = 'admin'
API_AUTHORIZE = 'authorize'
API_COMMENT = 'comment'
API_COMMENTS = 'comments'
API_CREATE = 'create'
API_CLEANUP = 'cleanup'
API_DELETE = 'delete'
API_FAVORITE = 'favorite'
API_FAVORITED = 'favorited'
API_GET = 'get'
API_HOME = 'home'
API_LEAVE = 'leave'
API_LOGIN = 'login'
API_JOIN = 'join'
API_PUBLIC = 'public'
API_QUERY = 'query'
API_REPLY = 'reply'
API_REPORT = 'report'
API_REPOST = 'repost'
API_UPDATE = 'update'
API_VIEW = 'view'
API_WATCH = 'watch'
API_UNWATCH = 'unwatch'
API_UNAUTHORIZE = 'unauthorize'
API_UNFAVORITE = 'unfavorite'

class Panda(Exception):
    """Base class for Twitter errors"""

    @property
    def message(self):
        """Returns the first argument used to construct this error."""
        return self.args[0]

class User(object):
    """Represent a user in our test system."""
    
    def __init__(self, values):
        """Create a user from the dictionary response."""

        self.user_id = values.get("id", "")
        self.realish_name = values.get("realish_name", "")
        self.screen_name = values.get("screen_name", "")
        self.display_name = values.get("display_name", "")
        # private data
        self.email = values.get("email", "")
        self.created = values.get("created", "")
        self.location = values.get("location", "")
        self.bio = values.get("bio", "")
        self.home = values.get("home", "")
        self.private = values.get("private", False)
        self.premium = values.get("premium", False)
        self.badges = values.get("badges", [])
        self.flagged = values.get("flagged", "")
        self.watches = values.get("watches")

    @staticmethod
    def from_jsondict(data):
        return User(data)

    def __str__(self):
        return "id: %s, screen_name: %s, realish_name: %s, email: %s, created: %s, location: %s, badges: %s" \
            % (self.user_id, self.screen_name, self.realish_name, self.email, self.created, self.location, self.badges)

class Post(object):
    """Represent a post in our test system -- metadata only."""
    
    def __init__(self, values):
        """Createa  post from the dictionary response."""

        self.post_id = values.get("id")
        self.author = values.get("author")
        self.created = values.get("created")
        self.location = values.get("location", "")
        self.file = values.get("file", "")
        self.content_type = values.get("content-type", "")
        self.tags = values.get("tags")
        self.enjoyed = values.get("enjoyed")
        self.disliked = values.get("disliked", 0)
        self.viewed = values.get("viewed")
        self.favorite_of_user = values.get("favorite_of_user", False)

    @staticmethod
    def from_jsondict(data):
        return Post(data)

    def __str__(self):
        return "id: %s, author: %s, created: %s, location: %s, tags: %s" \
            % (self.post_id, self.author, self.created, self.location, self.tags)

class Api(object):
    """Object that interacts with the API."""
    
    def __init__(self, author=''):
        """Instantiate; will need parameters later.
        
        author is used with create() -- later this will just come from auth."""
    
        self.author = author
        
        # XXX: currently unused
    
    def _get_raw(self, response):
        """Get the Raw data."""
        
        length = response.headers.get('content-length', None)
        
        print response.headers
        
        #if length is None:
        return response.read()
        #else:
        #    return response.read(length)
    
    def _parse(self, params):
        """dictionary of key,value pairs."""
        
        if params is None:
            return None

        # I am under the impression this doesn't allow you to just set a key
        # sans value.
        #
        # Also, if there is text space in here, it won't properly quote it.
        quotelist = []
        for k, v in params.items():
            quotelist.append("%s=%s" % (str(k), str(urllib.quote(str(v)))))

        return "&".join(quotelist)

#        return urllib.urlencode(dict([(k, v) for k, v in params.items() \
 #                                     if v is not None]))
    
    def _build(self, url, params):
        """Build URL."""
        
        if params:
            return url + '?' + self._parse(params)
        
        return url
    
    def _fetchmp(self, url, params, post_data):
        """Grab the results for the URL built."""
        
        raw = None

        # http://stackoverflow.com/questions/680305/using-multipartposthandler-to-post-form-data-with-python
        from poster.encode import multipart_encode
        from poster.streaminghttp import register_openers
        
        register_openers()
        datagen, headers = multipart_encode(post_data)
        request = urllib2.Request(url, datagen, headers)
        
        try:
            raw = urllib2.urlopen(request).read()
        except urllib2.HTTPError, e:
            print e
        
        # manually:
        # http://code.activestate.com/recipes/146306/

        return raw     
    
    def _fetch(self, url, params, post_data=None):
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

        raw = self._get_raw(response)

        opener.close()

        return raw

    def admin(self, request=None):
        """Run the admin query -- dumps everything."""

        url  = "%s/%s/%s" % (BASE_URL, POST_URL, API_ADMIN)

        if request is None:
            json = self._fetch(url, None, {"code" : 58780932341})
        else:
            json = self._fetch(url, None, {"code" : 58780932341,
                                           "request" : request})

        return simplejson.loads(json)

    def user_favorited(self, user_id, post_id):
        """Did this user favorite this post?"""

        url  = "%s/%s/%s" % (BASE_URL, USER_URL, API_FAVORITED)

        json = self._fetch(url, {"user" : str(user_id), "post" : str(post_id)})

        data = simplejson.loads(json)

        return data

    def get_user(self, user_id, full=False):
        """Get the user JSON with id."""
        
        url  = "%s/%s/%s" % (BASE_URL, USER_URL, API_GET)

        if full:
            json = self._fetch(url, {"id" : str(user_id), "full" : "true"})
        else:
            json = self._fetch(url, {"id" : str(user_id)})
                
        data = simplejson.loads(json)

        return User.from_jsondict(data)
    
    def update_user(self, user_id, field, value):
        """Update the user given the params."""

        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_UPDATE)

        # could likely just use mp for everything, :P
        if field == "avatar":
            self._fetchmp(url, None, {"user" : str(user_id), field : value})
            return

        if field not in ("realish_name", "location", "home", "display_name",):
            return

        self._fetch(url, None, {"user" : str(user_id), field : value})

    def login_user(self, screen_name):
        """Login for the user."""
        
        url  = "%s/%s/%s" % (BASE_URL, USER_URL, API_LOGIN)

        json = self._fetch(url, {"screen_name" : str(screen_name)})

        data = simplejson.loads(json)
        
        return data

    def get_post(self, post_id):
        """Get the post JSON with id."""
        
        url  = "%s/%s/%s" % (BASE_URL, POST_URL, API_GET)

        json = self._fetch(url, {"id" : str(post_id)})        
        data = simplejson.loads(json)
        
        return Post.from_jsondict(data[0])

    def query_user(self, query, user_id):
        """Query the data."""

        valid_params = ("community", "watchlist")

        if query not in valid_params:
            return None

        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_QUERY)

        json = self._fetch(url, {"query" : query, "id" : str(user_id)})

        data = simplejson.loads(json)

    def public(self, user_id = None):
        """Get the posts from the public stream."""

        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_PUBLIC)

        if user_id is not None:
            json = self._fetch(url, {"user" : str(user_id)})
        else:
            json = self._fetch(url, None)

        data = simplejson.loads(json)

        return [Post.from_jsondict(x) for x in data]

    def query(self, params, user_id = None):
        """Get the posts.
        
        params := ['param', 'value']."""

        valid_params = ("author", "tag", "reply_to", "screen_name",
                        "community", "repost_of")

        if len(params) != 2:
            return None

        if params[0] not in valid_params:
            return None

        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_QUERY)

        if user_id is not None:
            json = self._fetch(url, {params[0] : str(params[1]),
                                     "user" : str(user_id)})
        else:
            json = self._fetch(url, {params[0] : str(params[1])})

        data = simplejson.loads(json)
        
        return [Post.from_jsondict(x) for x in data]

    def query_home(self, user_id):
        """Get your home posts."""

        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_HOME)

        json = self._fetch(url, {"id" : str(user_id)})
        
        data = simplejson.loads(json)
        
        return data

    def delete_post(self, post_id):
        """Delete a post."""
        
        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_DELETE)
        
        json = self._fetch(url, None, {"id" : str(post_id),
                                       "code" : 58780932341})
        
        return json
    
    def delete_user(self, user_id):
        """Delete a user."""
        
        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_DELETE)

        json = self._fetch(url, None, {"id" : str(user_id),
                                       "code" : 58780932341})
        
        return json
    
    def join_community(self, user_id, community):
        """Join a community.  Here community is an array."""
        
        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_JOIN)

        json = self._fetch(url, None, {"user" : str(user_id),
                                       "community" : ",".join(community)})
        
        return json

    def leave_community(self, user_id, community):
        """Leave a community.  Here community is an array."""
        
        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_LEAVE)

        json = self._fetch(url, None, {"user" : str(user_id),
                                       "community" : ",".join(community)})
        
        return json

    def create_post(self, author, tags, file_data):
        """Create a post."""
        
        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_CREATE)
        
        # need to pull from image
        post_data = {"location" : "temp",
                     "author" : author,
                     "tags" : ",".join(tags),
                     "code" : 98098098098,
                     "data" : file_data}

        return simplejson.loads(self._fetchmp(url, None, post_data))

    def favorite_post(self, user_id, post_id):
        """Mark a post as favorited."""
        
        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_FAVORITE)
        
        json = self._fetch(url, None, {"user" : str(user_id), "post" : str(post_id)})
        
        return json

    def reply_post(self, reply_to, author, tags, file_data):
        """Reply to a post"""
        
        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_REPLY)
        
        # need to pull from image
        post_data = {"location" : "temp",
                     "author" : author,
                     "tags" : ",".join(tags),
                     "code" : 98098098098,
                     "reply_to" : reply_to,
                     "data" : file_data}

        return simplejson.loads(self._fetchmp(url, None, post_data))

    def repost_post(self, repost_of, author, tags):
        """Re-post a post."""
        
        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_REPOST)
        
        # need to pull from image
        post_data = {"location" : "temp",
                     "author" : author,
                     "tags" : ",".join(tags),
                     "code" : 98098098098,
                     "repost_of" : repost_of}

        json = self._fetchmp(url, None, post_data)
        print json

        #return simplejson.loads(self._fetchmp(url, None, post_data))

    def create_user(self, realish_name, display_name, email):
        """Create a user, only the metadata versus using files.
        
        display_name is used for the screen_name."""
            
        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_CREATE)
        
        post_data = {"bio" : "bio_stuff",
                     "display_name" : display_name,
                     "realish_name" : realish_name,
                     "location" : "here",
                     "email" : email,
                     "home" : "www.yup.com",
                     "code" : 98098098098}

        #return simplejson.loads()
        return self._fetch(url, None, post_data)

    def watch_user(self, watcher, watched):
        """Create a watch relationship between watch and watched."""
        
        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_WATCH)
        
        post_data = {"author" : watcher,
                     "watched" : watched,
                     "code" : 98098098098}
        
        json = self._fetch(url, None, post_data)

        print json
        #data = simplejson.loads(json)
        #return Post.from_jsondict(data)

    def unwatch_user(self, watcher, watched):
        """Create a watch relationship between watch and watched."""
        
        url = "%s/%s/%s" % (BASE_URL, USER_URL, API_UNWATCH)
        
        post_data = {"author" : watcher,
                     "watched" : watched,
                     "code" : 98098098098}

        json = self._fetch(url, None, post_data)

        print json
        #data = simplejson.loads(json)
        #return Post.from_jsondict(data)

    def cleanup_posts(self):
        """Deletes files without pointers."""
        
        url = "%s/%s/%s" % (BASE_URL, POST_URL, API_CLEANUP)

        json = self._fetch(url, None, {"code" : 58780932341})

        print json
        #data = simplejson.loads(json)
        #return Post.from_jsondict(data)
        
        #print data
        