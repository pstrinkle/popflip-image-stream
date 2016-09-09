"""Favorited API Call handler for snapshots."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("user", "post",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def check_enjoy(author_id, post_id):
    """Given an author and a post, check to see if they already marked it as
    enjoyed.  At first, this check seemed like a waste, but why not."""
    
    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['favorites']

    try:
        post = collection.find_one({"$and" : [{"user" : ObjectId(author_id)},
                                              {"post" : ObjectId(post_id)}]})
    except InvalidId:
        post = None
    
    connection.close()
    
    return post

def validate_get_handler(query_string):
    """Validate the request is simply id=val."""
    
    query_dict = parse_qs(query_string, keep_blank_values=True)

    return query_dict

def handle_new_post(query_dict):
    """Does not handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""
    
    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return {"value" : False}

    # not yet safe to use.
    post_id = str(string_from_interwebs(query_dict["post"][0])).strip()
    author_id = str(string_from_interwebs(query_dict["user"][0])).strip()
    
    if check_enjoy(author_id, post_id) is not None:
        return {"value" : True}

    return {"value" : False}

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

    ##### parameters are never safe
    query_dict = validate_get_handler(environ['QUERY_STRING'])

    processed_post = handle_new_post(query_dict)
    output.append(dumps(processed_post))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
