"""Public API Call handler for snapshots."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo import DESCENDING
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

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

    if len(query_dict) > 2:
        return None
    
    return query_dict

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


def handle_public():
    """Query the localhost mongodb instance for all posts from this author.
    
    Always escape values taken from query_dict."""

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['posts']

    posts = []

    # limit i wonder... should play around with this; I wonder what 
    # pre-processing is done.
    try:
        for post in collection.find().sort("created", DESCENDING).limit(200):
            posts.append(cleanup_post(post))
    except InvalidId:
        posts = None

    connection.close()

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

def handle_post_data_addition(results, query_dict):
    """For each post in results, add if this user liked, or favorited each 
    post."""
    
    try:
        user_id = str(string_from_interwebs(query_dict["user"][0]))
    except ValueError:
        return
    
    connection = Connection('localhost', 27017)
    
    for post in results:
        post["favorite_of_user"] = \
            user_favorited_post(user_id, post["id"], connection)

    connection.close()

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

    query_dict = validate_query_handler(environ['QUERY_STRING'])

    if query_dict is None:
        bad_request(start_response)
        return output

    results = handle_public()

    # when given an invalid query parameter it returns None, otherwise it 
    # returns an empty array (which is a valid response).
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

