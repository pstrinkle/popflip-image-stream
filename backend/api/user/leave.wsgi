"""Unwatch API Handler."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from urllib import unquote

PARAMS = {"dbh" : 'localhost', # database host
          "dbp" : 27017,       # database port
          "dbn" : 'test',      # database name
          }

POST_REQUIRED_PARAMS = ("user", "community",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def update_involved(user, connection):
    """Decrement the communities value for the user."""

    database = connection['test']
    collection = database['users']

    collection.update({"_id" : ObjectId(user)},
                      {"$inc" : {"communities" : -1}})
    
    return

def verify_author(user, connection):
    """Given an author id, check it."""

    database = connection['test']
    collection = database['users']

    try:
        post_a = collection.find_one({"_id" : ObjectId(user)})
    except InvalidId:
        post_a = None

    if post_a is None:
        return False

    return True

def handle_new_join(post_data):
    """Add new watch to database if input is correct."""
    
    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return False

    user = string_from_interwebs(query_dict.get("user")[0]).strip()
    community = string_from_interwebs(query_dict.get("community")[0]).strip()
    
    split_tags = [string_from_interwebs(tag).strip() for tag in community.split(",")] # temporary

    # XXX: Need to search each tag for illegal characters and also check the
    # string length.
    if len(split_tags) > 2:
        return False

    with Connection('localhost', 27017) as connection:
        # verify parameters.
        if not verify_author(user, connection):
            return False

        database = connection['test']
        collection = database['communities']

        # need to wrap with try, except
        try:
            post = collection.find_one({"$and" : [{"user" : ObjectId(user)},
                                                  {"community" : split_tags}]})
        except InvalidId:
            post = None

        if post is not None:
            collection.remove({"_id" : ObjectId(post["_id"])})
            update_involved(user, connection)

    # could not be found.
    if post is None:
        return False

    return True

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """wsgi entry point."""

    output = []
    outtype = "application/json"

    if environ['REQUEST_METHOD'] == 'GET':
        bad_request(start_response)
        return output

    # this simplifies parameter parsing.
    if environ['CONTENT_TYPE'] == 'application/x-www-form-urlencoded':
        try:
            content_length = int(environ['CONTENT_LENGTH'])
        except ValueError:
            content_length = 0
            
        # show form data as received by POST:
        post_data = environ['wsgi.input'].read(content_length)
        
        success = handle_new_join(post_data)
        if not success:
            bad_request(start_response)
            return output

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
