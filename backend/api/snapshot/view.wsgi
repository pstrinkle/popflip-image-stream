"""View API Call handler for snapshots."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from boto.s3.connection import S3Connection
from urllib import unquote

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def validate_get_handler(query_string):
    """Validate the request is simply id=val."""
    
    query_dict = parse_qs(query_string, keep_blank_values=True)
    
    if len(query_dict) > 3:
        return None

    if "id" not in query_dict:
        return None

    return query_dict

def handle_get(query_dict):
    """Return a cleaned copy of the JSON."""    
    
    output = []
    
    if query_dict is None:
        return None

    #only handles first
    try:
        post_id = str(string_from_interwebs(query_dict["id"][0]))
    except ValueError:
        return None

    thumbnail = False
    largeview = False

    if "thumbnail" in query_dict:
        thumbnail = True
    if "large" in query_dict:
        largeview = True

    post = None

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['posts']

        try:
            post = collection.find_one({"_id" : ObjectId(post_id)})
        except InvalidId:
            pass

    if post is None:
        return None

    # so that we draw the original document
    # later when we start expiring off posts, this pull won't necessarily work.
    # need to get the filename from the image field; creating, replying and 
    # re-posting need to set the image field, we can just check that.
    if "repost_of" in post:
        s3_key = str(post["file"])
    else:
        s3_key = post_id

    conn = S3Connection(aws_access_key_id, aws_secret_access_key)
    bucket = conn.get_bucket('hyperionstorm')
    # currently the images are stored in the data folder; also, we need to check
    #  the mime type to determine what we output.
    #
    # bucket.get_key returns None if it doesn't exist.
    if thumbnail:
        key = bucket.get_key("data/%s_tiny.jpg" % s3_key)
    elif largeview:
        key = bucket.get_key("data/%s_lrg.jpg" % s3_key)

        if key is None:
            key = bucket.get_key("data/%s.jpg" % s3_key)
    else:
        key = bucket.get_key("data/%s.jpg" % s3_key)

    try:
        file_as_string = key.get_contents_as_string()
        output.append(file_as_string)
    except Exception, e:
        conn.close()
        return output

    conn.close()
    return output

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """Entry point for all wsgi applications."""

    output = []

    query_dict = validate_get_handler(environ['QUERY_STRING'])

    result = handle_get(query_dict)

    if result is None:
        bad_request(start_response)
        return output

    output.extend(result)

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'image/jpeg'),
                        ('Content-Length', str(output_len))])

    # image/jpeg
    return output
