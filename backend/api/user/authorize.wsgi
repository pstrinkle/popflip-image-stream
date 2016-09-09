"""Authorize API Handler."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from urllib import unquote

POST_REQUIRED_PARAMS = ("authorized", "authorizer",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def verify_authors(user_a, user_b, connection):
    """Given an author id, check it."""

    database = connection['test']
    collection = database['users']

    try:
        post_a = collection.find_one({"_id" : ObjectId(user_a)})
        post_b = collection.find_one({"_id" : ObjectId(user_b)})
    except InvalidId:
        post_a = None
        post_b = None

    if post_a is None or post_b is None:
        return False

    return True

def handle_new_authorizer(post_data):
    """Add new watch to database if input is correct."""

    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return False

    authorizer = string_from_interwebs(query_dict.get("authorizer")[0]).strip()
    authorized = string_from_interwebs(query_dict.get("authorized")[0]).strip()

    # Connection supports .__enter__, .__exit__
    with Connection('localhost', 27017) as connection:
        if not verify_authors(authorized, authorizer, connection):
            return False

        database = connection['test']
        collection = database['commenters'] # I think this is spelled incorrectly.

        new_auth = {"authorizer" : ObjectId(authorizer),
                    "authorized" : ObjectId(authorized)}

        # might be a better way to check this.
        check_comm_auth = collection.find_one({"$and" : [{"authorizer" : ObjectId(authorizer)},
                                                         {"authorized" : ObjectId(authorized)}]})

        # if it's a duplicate we silently fail.
        if check_comm_auth is None:
            # need to wrap with try, except
            collection.insert(new_auth)

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
        
        success = handle_new_authorizer(post_data)
        if not success:
            bad_request(start_response)
            return output

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
