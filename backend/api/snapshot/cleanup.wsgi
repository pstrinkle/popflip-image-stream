"""This goes through the S3 keys and deletes any that don't have corresponding
entries in the posts database."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from boto.s3.connection import S3Connection
from json import dumps


POST_REQUIRED_PARAMS = ("code",)

def handle_delete(query_dict):
    """Just tries to delete the entry; and any file associated with it."""

    deleted = []

    if query_dict is None:
        return False

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['posts']
    
    conn = S3Connection(aws_access_key_id, aws_secret_access_key)
    bucket = conn.get_bucket('hyperionstorm')

    files = bucket.list("data/")
    
    for file_key in files:
        if ".jpg" not in file_key.key:
            continue

        curr = file_key.key.replace("data/","").replace(".jpg","").replace("_tiny", "")

        try:
            post = collection.find_one({"_id" : ObjectId(curr)})
        except InvalidId:
            post = None
            
        if post is None:
            deleted.append(curr)
            bucket.delete_key(file_key.key)

    connection.close()
    conn.close()

    return deleted

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
            
        if len(query_dict) != 1:
            bad_request(start_response)
            return output
        
        for param in POST_REQUIRED_PARAMS:
            if param not in query_dict:
                bad_request(start_response)
                return output
        
        try:
            key = int(escape(query_dict["code"][0]))
        except KeyError:
            key = 0

        if key == 58780932341:
            deleted = handle_delete(query_dict)
            
            output.extend(dumps(deleted, indent=4))

        outtype = "application/json"

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
