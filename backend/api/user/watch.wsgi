"""Watch API Handler."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from urllib import unquote

POST_REQUIRED_PARAMS = ("author", "watched", "code",)
MAX_WATCHES = 1000

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

# db.users.update({"_id" : ObjectId("4ffb168d5e358e377900000a")},
#                 { $set : {"watched" : 0} }, false, false) 
def update_involved(watcher, watched, connection):
    """Increment the watches value for the user."""

    database = connection['test']
    collection = database['users']

    collection.update({"_id" : ObjectId(watcher)},
                      {"$inc" : {"watching" : 1}})
    
    collection.update({"_id" : ObjectId(watched)},
                      {"$inc" : {"watched" : 1}})

    return

def check_count(author, connection):
    """Given an author id, check to make sure it has fewer than MAX watches."""

    database = connection['test']
    collection = database['users']

    post = collection.find_one({"_id" : ObjectId(author)})

    if post["watching"] >= MAX_WATCHES:
        return True
    
    return False

def verify_authors(watcher, watched, connection):
    """Given an author id, check it."""

    database = connection['test']
    collection = database['users']

    try:
        post_a = collection.find_one({"_id" : ObjectId(watcher)})
        post_b = collection.find_one({"_id" : ObjectId(watched)})
    except InvalidId:
        post_a = None
        post_b = None

    if post_a is None or post_b is None:
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
    
    # Connection supports .__enter__, .__exit__
    with Connection('localhost', 27017) as connection:
        if not verify_authors(author, watched, connection):
            return False

        if check_count(author, connection):
            return False

        database = connection['test']
        collection = database['watches']

        watch = {"author" : ObjectId(author), "watched" : ObjectId(watched)}
        
        # might be a better way to check this.
        check_watch = collection.find_one({"$and" : [{"author" : ObjectId(author)},
                                                     {"watched" : ObjectId(watched)}]})

        # if it's a duplicate we silently fail.
        if check_watch is None:
            # need to wrap with try, except
            collection.insert(watch)
    
            update_involved(author, watched, connection)

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
