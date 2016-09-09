"""Call snapshot/home()."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote
import operator

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

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

def sort_and_clean(posts):
    """Sort and clean."""
    
    sorted_posts = sorted(posts, key=operator.itemgetter("created"), reverse=True)
    
    return [cleanup_post(post) for post in sorted_posts]

def handle_watches(author, connection):
    """Return an array of watches for the author."""

    database = connection['test']
    collection = database['watches']
    
    watches = []

    # this should not except
    try:
        for post in collection.find({"author" : ObjectId(author)}):
            watches.append(post)
    except InvalidId:
        return None
    
    return watches

def handle_author_query(author_id, connection):
    """Query the localhost mongodb instance for all posts from this author.
    
    Always escape values taken from query_dict."""

    database = connection['test']
    collection = database['posts']

    posts = []

    try:
        for post in collection.find({"author" : ObjectId(author_id)}):
            posts.append(post)
    except InvalidId:
        posts = None

    if posts is None:
        return None

    return posts

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

def handle_post_data_addition(results, user_id, connection):
    """For each post in results, add if this user liked, or favorited each 
    post.
    
    This is slightly different than the version in query."""

    for post in results:
        post["favorite_of_user"] = \
            user_favorited_post(user_id, post["id"], connection)

def build_home(query_string):
    """Build the response."""
    
    query_dict = parse_qs(query_string, keep_blank_values=True)
    
    if "id" not in query_dict:
        return None
    
    try:
        user_id = str(string_from_interwebs(query_dict["id"][0]))
    except ValueError:
        return None
    
    posts = []

    with Connection('localhost', 27017) as connection:
        watches = handle_watches(user_id, connection)

        # invalid user.
        if watches is None:
            return None

        for watch in watches:
            posts.extend(handle_author_query(watch["watched"], connection))

        posts = sort_and_clean(posts)

        handle_post_data_addition(posts, user_id, connection)

    # latest is 0th.
    return posts

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

    results = build_home(environ['QUERY_STRING'])

    # when given an invalid query parameter it returns None, otherwise it 
    # returns an empty array (which is a valid response).
    if results is None:
        bad_request(start_response)
        return output

    # sometimes I handle this at a different level.
    # I will become consistent over time.
    output.append(dumps(results, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output