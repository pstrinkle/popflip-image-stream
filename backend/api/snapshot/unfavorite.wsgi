"""Unfavorite API Call handler for snapshots."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from urllib import unquote

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("user", "post",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def update_post(post_id, connection):
    """Given a post id, update it's flagged."""

    database = connection['test']
    collection = database['posts']

    collection.update({"_id" : ObjectId(post_id)},
                      {"$inc" : {"enjoyed" : -1}})

def delete_favorite(favorite, connection):
    """Delete the favorite entry."""

    database = connection['test']
    collection = database['favorites']

    collection.remove({"_id" : ObjectId(favorite["_id"])})

def check_favorite(author_id, post_id, connection):
    """Given an author and a post, check to see if they already marked it as
    favorite.  At first, this check seemed like a waste, but why not."""

    database = connection['test']
    collection = database['favorites']

    # need to wrap with try, except
    try:
        post = collection.find_one({"$and" : [{"user" : ObjectId(author_id)},
                                              {"post" : ObjectId(post_id)}]})
    except InvalidId:
        post = None

    return post

def handle_new_favorite(query_dict):
    """Does not handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""
    
    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return False

    # not yet safe to use.
    post_id = str(string_from_interwebs(query_dict["post"][0])).strip()
    author_id = str(string_from_interwebs(query_dict["user"][0])).strip()
    
    with Connection('localhost', 27017) as connection:
        favorite = check_favorite(author_id, post_id, connection)
        
        if favorite is not None:
            delete_favorite(favorite, connection)
            update_post(post_id, connection)
            return True

    return False
    
def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output = []
    output_len = sum(len(line) for line in output)
    start_response('400 Bad Request',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])
    
    return output

def application(environ, start_response):
    """Entry point for all wsgi applications."""

    output = []

    if environ['REQUEST_METHOD'] == 'GET':
        return bad_request(start_response)

    ##### parameters are never safe
    try:
        content_length = int(environ['CONTENT_LENGTH'])
    except ValueError:
        content_length = 0
    
    post_data = environ['wsgi.input'].read(content_length)

    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    success = handle_new_favorite(query_dict)
    if not success:
        return bad_request(start_response)

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
