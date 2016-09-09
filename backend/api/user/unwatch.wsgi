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

POST_REQUIRED_PARAMS = ("author", "watched", "code",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def update_involved(watcher, watched):
    """Increment the watches value for the user."""

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['users']

    collection.update({"_id" : ObjectId(watcher)},
                      {"$inc" : {"watching" : -1}})
    collection.update({"_id" : ObjectId(watched)},
                      {"$inc" : {"watched" : -1}})

    connection.close()
    
    return

def verify_authors(watcher, watched):
    """Given an author id, check it."""
    
    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['users']

    try:
        postA = collection.find_one({"_id" : ObjectId(watcher)})
        postB = collection.find_one({"_id" : ObjectId(watched)})
    except InvalidId:
        postA = None
        postB = None
    
    connection.close()
    
    if postA is None or postB is None:
        return False

    return True

def handle_new_watch(post_data):
    """Add new watch to database if input is correct."""
    
    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return False

    try:
        value = int(string_from_interwebs(query_dict["code"][0]))
    except ValueError:
        return False
    
    if value != 98098098098:
        return False

    author = string_from_interwebs(query_dict.get("author")[0]).strip()
    watched = string_from_interwebs(query_dict.get("watched")[0]).strip()
    
    # verify parameters.
    if not verify_authors(author, watched):
        return False

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['watches']

    # need to wrap with try, except
    try:
        post = collection.find_one({"$and" : [{"author" : ObjectId(author)},
                                              {"watched" : ObjectId(watched)}]})
    except InvalidId:
        post = None

    if post is not None:
        collection.remove({"_id" : ObjectId(post["_id"])})
        update_involved(author, watched)

    connection.close()

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
        
        success = handle_new_watch(post_data)
        if not success:
            bad_request(start_response)
            return output

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
