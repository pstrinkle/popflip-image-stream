"""Delete Handler."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from boto.s3.connection import S3Connection
from urllib import unquote

POST_REQUIRED_PARAMS = ("id", "code",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def decrement_reply(connection, reply_to):
    """Given a source id, decrement its num_replies."""

    database = connection['test']
    collection = database['posts']

    collection.update({"_id" : ObjectId(reply_to)},
                      {"$inc" : {"num_replies" : -1}})

def decrement_repost(connection, repost_of):
    """Given a source id, decrement its num_reposts."""
    
    database = connection['test']
    collection = database['posts']

    collection.update({"_id" : ObjectId(repost_of)},
                      {"$inc" : {"num_reposts" : -1}})

def verify_and_retrieve_post(connection, post_id):
    """Given a post id, check it."""

    database = connection['test']
    collection = database['posts']

    try:
        post = collection.find_one({"_id" : ObjectId(post_id)})
    except InvalidId:
        post = None

    return post

def handle_delete(query_dict):
    """Just tries to delete the entry; and any file associated with it."""

    complete_success = True

    if query_dict is None:
        return False

    #only handles first
    try:
        post_id = str(string_from_interwebs(query_dict["id"][0]))
    except ValueError:
        return False

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']
    
        post = verify_and_retrieve_post(connection, post_id)
        if post is None:
            return False
    
        if "reply_to" in post:
            decrement_reply(connection, post["reply_to"])
    
        if "repost_of" in post:
            decrement_repost(connection, post["repost_of"])

        try:
            collection.remove({"_id" : ObjectId(post_id)})
        except InvalidId:
            complete_success = False
        
        # XXX: Delete all favorites.
        
        # Delete all the comments.
        collection = database['comments']
        try:
            for post in collection.find({"post" : ObjectId(post_id)}):
                collection.remove({"_id" : post["_id"]})
        except InvalidId:
            complete_success = False

    conn = S3Connection(aws_access_key_id, aws_secret_access_key)
    bucket = conn.get_bucket('hyperionstorm')
    # currently the images are stored in the data folder; also, we need to check
    #  the mime type to determine what we output.
    bucket.delete_key("data/%s_lrg.jpg" % post_id)
    bucket.delete_key("data/%s.jpg" % post_id)
    bucket.delete_key("data/%s_tiny.jpg" % post_id)
    conn.close()

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
