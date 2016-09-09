"""Delete Handler."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from urllib import unquote

POST_REQUIRED_PARAMS = ("id", "code",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def update_comment_count(post_id, connection):
    """This decrements the comment count for the post."""
    
    database = connection['test']
    collection = database['posts']

    try:
        collection.update({"_id" : post_id}, {"$inc" : {"comments" : -1}})
    except InvalidId:
        pass

def handle_delete(query_dict):
    """Just tries to delete the entry; and any file associated with it."""

    complete_success = True

    if query_dict is None:
        return False

    #only handles first
    try:
        user_id = str(string_from_interwebs(query_dict["id"][0]))
    except ValueError:
        return False

    with Connection('localhost', 27017) as connection:
        database = connection['test']

        collection = database['users']
        try:
            collection.remove({"_id" : ObjectId(user_id)})
        except InvalidId:
            complete_success = False
        
        collection = database['commenters'] # I bet this is spelled wrong.
        try:
            for post in collection.find({"authorizer" : ObjectId(user_id)}):
                collection.remove({"_id" : post["_id"]})
            for post in collection.find({"authorized" : ObjectId(user_id)}):
                collection.remove({"_id" : post["_id"]})
        except InvalidId:
            complete_success = False
        
        # doesn't update counts, but fuck it; I'm ditching certain counts.
        collection = database['watches']
        try:
            for post in collection.find({"author" : ObjectId(user_id)}):
                collection.remove({"_id" : post["_id"]})
            for post in collection.find({"watched" : ObjectId(user_id)}):
                collection.remove({"_id" : post["_id"]})
        except InvalidId:
            complete_success = False

        # does update the count.
        collection = database['comments']
        try:
            for post in collection.find({"user" : ObjectId(user_id)}):
                collection.remove({"_id" : post["_id"]})
                update_comment_count(post["post"], connection)
        except InvalidId:
            complete_success = False
        
        # XXX: doesn't delete favorites.

    return complete_success

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """wsgi entry point."""

    output = []
    outtype = "text/html"

    if environ['REQUEST_METHOD'] == 'GET':
        bad_request(start_response)
        return output
    
    if environ['CONTENT_TYPE'] == 'application/x-www-form-urlencoded':
        try:
            content_length = int(environ['CONTENT_LENGTH'])
        except ValueError:
            content_length = 0
            
        # show form data as received by POST:
        post_data = environ['wsgi.input'].read(content_length)

        # likely throws an exception on parse error.
        query_dict = parse_qs(post_data, keep_blank_values=True)
            
        if len(query_dict) != 2:
            bad_request(start_response)
            return output
        
        for param in POST_REQUIRED_PARAMS:
            if param not in query_dict:
                bad_request(start_response)
                return output
        
        try:
            key = int(string_from_interwebs(query_dict["code"][0]))
        except KeyError:
            key = 0

        if key == 58780932341:
            success = handle_delete(query_dict)
            
            if not success:
                bad_request(start_response)
                return output

        outtype = "application/json"

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
