"""Query API Call handler for snapshots."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo import DESCENDING
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

QUERY_INVALID = 0
QUERY_AUTHOR = 1
QUERY_TAG = 2
QUERY_REPLIES = 3
QUERY_SCREENNAME = 4
QUERY_COMMUNITY = 5
QUERY_REPOSTS = 6

# this won't work quite right when we transition to handle other queries, 
# likely this will be refactored into a class that can support building complex 
# queries.
SUPPORTED_QUERIES = {
                     "author" : QUERY_AUTHOR,
                     "tag" : QUERY_TAG,
                     "reply_to" : QUERY_REPLIES,
                     "repost_of" : QUERY_REPOSTS,
                     "screen_name" : QUERY_SCREENNAME,
                     "community" : QUERY_COMMUNITY
                     }

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def validate_query_handler(query_string):
    """Verify the input query is some level of valid, right now it does not 
    check the value sent, just the key.

    Currently only support one key, value pair -- but does verify this is 
    supplied."""

    # likely throws an exception on parse error.
    query_dict = parse_qs(query_string, keep_blank_values=True)

    # user_id, since_id, and query
    if len(query_dict) > 3:
        return QUERY_INVALID, None

    # currently, this only supports the notion of one query available.
    for key in SUPPORTED_QUERIES:
        if key in query_dict:
            return SUPPORTED_QUERIES[key], query_dict
    
    return QUERY_INVALID, None

def cleanup_post(post):
    """Given a dictionary of a post, return a new dictionary for output as 
    JSON"""
    
    post_data = post
    post_data["id"] = str(post["_id"])
    post_data["created"] = str(post["created"].ctime())
    post_data["author"] = str(post["author"])
    del post_data["_id"]
    
    if "reply_to" in post:
        post_data["reply_to"] = str(post["reply_to"])

    if "repost_of" in post:
        post_data["repost_of"] = str(post["repost_of"])

    return post_data

def screen_name_to_user(screen_name):
    """Convert a screen_name to a user_id."""
    
    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['users']
    
    user = collection.find_one({"screen_name" : screen_name})
    
    connection.close()
    
    if user is None:
        return None
    
    return str(user["_id"])

def handle_screenname_query(query_dict):
    """Query the localhost mongodb instance for all posts that are from the user
    with that screen_name."""
    
    try:
        screen_name = string_from_interwebs(query_dict["screen_name"][0])
    except ValueError:
        return None
    
    # convert screen_name to user_id.
    user = screen_name_to_user(screen_name.lower())
    
    if user is None:
        return None

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']
    
        # This should just call handle_author_query, but that may not be quite
        # what we want...  this will get refactored later.
        posts = []

        try:
            for post in collection.find({"author" : ObjectId(user)}).sort("created", DESCENDING):
                posts.append(cleanup_post(post))
        except InvalidId:
            posts = None

    return posts

def handle_repost_query(query_dict):
    """Query the localhost mongodb instance for all posts that are reposts to a
    specified post.
    
    Always escape values taken from query_dict."""

    #only handles first
    try:
        source = string_from_interwebs(query_dict["repost_of"][0])
    except ValueError:
        return None
    
    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']
    
        posts = []

        # this should not except
        for post in collection.find({"repost_of" : ObjectId(source)}).sort("created", DESCENDING):
            posts.append(cleanup_post(post))

    return posts

def handle_reply_query(query_dict):
    """Query the localhost mongodb instance for all posts that are replies to a
    specified post.
    
    Always escape values taken from query_dict."""

    #only handles first
    try:
        source = string_from_interwebs(query_dict["reply_to"][0])
    except ValueError:
        return None

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']

        posts = []

        # this should not except
        for post in collection.find({"reply_to" : ObjectId(source)}).sort("created", DESCENDING):
            posts.append(cleanup_post(post))

    return posts

def handle_community_query(query_dict):
    """Query the localhost mongodb instance for all posts within this community.
    
    Always escape values taken from query_dict."""

    #only handles first
    try:
        tags = string_from_interwebs(query_dict["community"][0])
    except ValueError:
        return None

    split_tags = [tag.strip() for tag in tags.split(",")]

    if len(split_tags) > 2:
        return None

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']

        posts = []

        # this should not except
        for post in collection.find({"tags" :
                                     {"$all" : [split_tags[0], split_tags[1]]}}).sort("created", DESCENDING):
            posts.append(cleanup_post(post))

    return posts

def handle_tag_query(query_dict):
    """Query the localhost mongodb instance for all posts with this tag.
    
    Always escape values taken from query_dict."""

    #only handles first
    try:
        tag = string_from_interwebs(query_dict["tag"][0])
    except ValueError:
        return None

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']

        posts = []

        # this should not except
        for post in collection.find({"tags" : tag}).sort("created", DESCENDING):
            posts.append(cleanup_post(post))

    return posts

def handle_author_query(query_dict):
    """Query the localhost mongodb instance for all posts from this author.
    
    Always escape values taken from query_dict."""

    #only handles first
    try:
        author_id = string_from_interwebs(query_dict["author"][0])
    except ValueError:
        return None

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']

        posts = []

        try:
            for post in collection.find({"author" : ObjectId(author_id)}).sort("created", DESCENDING):
                posts.append(cleanup_post(post))
        except InvalidId:
            posts = None

    return posts

# XXX: This is used here and in snapshot/get.
def user_favorited_post(user_id, post_id, connection):
    """Did the user favorite the post?"""

    database = connection['test']
    collection = database['favorites']

    try:
        post = collection.find_one({"$and" : [{"user" : ObjectId(user_id)},
                                              {"post" : ObjectId(post_id)}]})
    except InvalidId:
        post = None

    if post is None:
        return False
    
    return True

# XXX: This is used here and in snapshot/get.
def handle_post_data_addition(results, query_dict):
    """For each post in results, add if this user liked, or favorited each 
    post."""
    
    try:
        user_id = str(string_from_interwebs(query_dict["user"][0]))
    except ValueError:
        return

    with Connection('localhost', 27017) as connection:
        for post in results:
            post["favorite_of_user"] = \
                user_favorited_post(user_id, post["id"], connection)

def trim_results(results, query_dict):
    """Go through the results and delete posts older than since from the
    results."""

    # not sure what this exception is catching anymore.
    # but you can send up any string/number/thing as a parameter and it seems
    # to be fine if it can be represented as a string.
    try:
        since_id = str(string_from_interwebs(query_dict["since"][0]))
    except ValueError:
        return None

    for idx in range(0, len(results)):
        if results[idx]["id"] == since_id:
            if idx > 1:
                return results[0:idx-1]
            elif idx == 1:
                return [results[0]]
            else:
                return []
    
    return results

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """Entry point for all wsgi applications."""

    output = []

    if environ['REQUEST_METHOD'] == 'POST':
        bad_request(start_response)
        return output

    query_type, query_dict = validate_query_handler(environ['QUERY_STRING'])

    if query_type == QUERY_INVALID:
        bad_request(start_response)
        return output

    # I could handle this with a simple call table in a dictionary.
    if query_type == QUERY_AUTHOR:
        results = handle_author_query(query_dict)
    elif query_type == QUERY_TAG:
        results = handle_tag_query(query_dict)
    elif query_type == QUERY_REPLIES:
        results = handle_reply_query(query_dict)
    elif query_type == QUERY_SCREENNAME:
        results = handle_screenname_query(query_dict)
    elif query_type == QUERY_COMMUNITY:
        results = handle_community_query(query_dict)
    elif query_type == QUERY_REPOSTS:
        results = handle_repost_query(query_dict)
    else:
        results = None

    # when given an invalid query parameter it returns None, otherwise it 
    # returns an empty array (which is a valid response).
    if results is None:
        bad_request(start_response)
        return output

    if "since" in query_dict:
        results = trim_results(results, query_dict)

    if results is None:
        bad_request(start_response)
        return output

    if "user" in query_dict:
        handle_post_data_addition(results, query_dict)

    output.append(dumps(results, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output

