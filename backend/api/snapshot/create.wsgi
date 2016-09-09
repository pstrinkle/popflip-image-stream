"""New API Call handler for snapshots."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from datetime import datetime
from urllib import unquote

# parse_multipart, parse_header
from cgi import escape, FieldStorage
from json import dumps
from boto.s3.connection import S3Connection
from boto.s3.key import Key

# from PIL
from PIL import Image
import cStringIO

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("tags", "author", "code", "data",)
POST_OPTIONAL_PARAMS = ("location",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def adjust_image_resolution(data):
    """Given image data, shrink it to no greater than 1024 for its larger
    dimension."""

    output_large = cStringIO.StringIO()
    output_default = cStringIO.StringIO()
    output_tiny = cStringIO.StringIO()
    
    try:
        im0 = Image.open(cStringIO.StringIO(data))
        im0.thumbnail((1280, 1280), Image.ANTIALIAS)
        im0.save(output_large, 'JPEG')

        im1 = Image.open(cStringIO.StringIO(data))
        im1.thumbnail((1024, 1024), Image.ANTIALIAS)
        # could run entropy check to see if GIF makes more sense given an item.
        im1.save(output_default, 'JPEG')
        
        im2 = Image.open(cStringIO.StringIO(data))
        im2.thumbnail((120, 120), Image.ANTIALIAS)
        im2.save(output_tiny, 'JPEG')
    except IOError:
        return None
    
    return {"large" : output_large.getvalue(),
            "default" : output_default.getvalue(),
            "tiny" : output_tiny.getvalue()}

def insert_data_into_storage(name, image_dict):
    """Given file contents, insert into S3."""

    # if S3Connection supports __enter__, and __exit__ then we can use with.
    conn = S3Connection(aws_access_key_id, aws_secret_access_key)
    bucket = conn.get_bucket('hyperionstorm')

    k_lrg = Key(bucket)
    k_lrg.key = "data/%s_lrg.jpg" % name

    k_dft = Key(bucket)
    k_dft.key = "data/%s.jpg" % name

    k_tiny = Key(bucket)
    k_tiny.key = "data/%s_tiny.jpg" % name

    try:
        k_lrg.set_contents_from_string(image_dict["large"])
        k_dft.set_contents_from_string(image_dict["default"])
        k_tiny.set_contents_from_string(image_dict["tiny"])
    except Exception, exp:
        conn.close()
        return False

    conn.close()
    return True

def verify_author(author):
    """Given an author id, check it."""
    
    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['users']

    try:
        post = collection.find_one({"_id" : ObjectId(author)})
    except InvalidId:
        post = None
    
    connection.close()
    
    if post is None:
        return False

    return True

def insert_post_into_db(post):
    """Given a post dictionary, insert it into database collection for posts."""
    
    if post is not None:
        connection = Connection('localhost', 27017)
        database = connection['test']
        collection = database['posts']

        # need to wrap with try, except
        entry = collection.insert(post)
        
        connection.close()
        
        return {"id" : str(entry)}
    
    return None

def handle_new_post(post_data, user_agent, remote_addr):
    """Does handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""
    
    for required in POST_REQUIRED_PARAMS:
        if required not in post_data:
            return None, None

    try:
        value = int(string_from_interwebs(post_data.getfirst("code", "")))
    except ValueError:
        return None, None

    if value != 98098098098:
        return None, None

    # not yet safe to use.
    location = post_data.getfirst("location", "")
    author = post_data.getfirst("author")

    # we do this here incase the input was: 
    #     "tag1,%20tag2,%20tag3" versus "tag1,tag2,tag3"
    tags = string_from_interwebs(post_data.getfirst("tags"))    

    # temporary
    split_tags = [string_from_interwebs(tag).strip().lower() for tag in tags.split(",")]

    # XXX: Need to search each tag for illegal characters and also check the
    # string length.

    if len(split_tags) > 3:
        return None, None

    author_id = string_from_interwebs(author).strip()

    if not verify_author(author_id):
        return None, None

    # XXX: Need to add length checks to user_agent, and location, and tags

    post = {"viewed"       : 0,
            "comments"     : 0,
            "flagged"      : 0,
            "disliked"     : 0,
            "enjoyed"      : 0,
            "num_replies"  : 0,
            "num_reposts"  : 0,
            "content-type" : "image", # need to pull this from the mime lookup
            "file"         : "placeholder",
            "user_agent"   : user_agent,
            "remote_addr"  : remote_addr,
            "author"       : ObjectId(author_id),
            "created"      : datetime.utcnow(),
            "location"     : string_from_interwebs(location).strip(),
            "tags"         : split_tags}

    return post_data.getfirst("data"), post
    
def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output = []
    output_len = sum(len(line) for line in output)
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])
    
    return output

def application(environ, start_response):
    """Entry point for all wsgi applications."""

    output = []

    if environ['REQUEST_METHOD'] == 'GET':
        bad_request(start_response)
        return output

    ##### parameters are never safe
    try:
        content_length = int(environ['CONTENT_LENGTH'])
    except ValueError:
        bad_request(start_response)
        return output
    
    # maximum file length is 5MiB
    if content_length > 5*1024*1024:
        bad_request(start_response)
        return output
    
    user_agent = environ.get('HTTP_USER_AGENT', '')
    remote_addr = environ.get('REMOTE_ADDR', '')
    
    # add CONTENT_TYPE check
    # FieldStorage is not the best solution because it reads the entire thing
    # into memory; what I need to do is get parse_headres and parse_multipart
    # working.
    post_env = environ.copy()
    post_env['QUERY_STRING'] = ''
    post = \
        FieldStorage(
                     fp=environ['wsgi.input'],
                     environ=post_env,
                     keep_blank_values=True)

    raw_data, processed_post = handle_new_post(post, user_agent, remote_addr)
    
    if raw_data is None: # if data is fine, processed_post is fine.
        bad_request(start_response)
        return output

    images = adjust_image_resolution(raw_data)

    if images is None: # should all be good.
        bad_request(start_response)
        return output

    entry = insert_post_into_db(processed_post)
    if entry is None:
        bad_request(start_response)
        return output

    success = insert_data_into_storage(str(entry["id"]), images)
    if success is False:
        # need to delete the database entry.
        bad_request(start_response)
        return output

    output.append(dumps(entry, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
