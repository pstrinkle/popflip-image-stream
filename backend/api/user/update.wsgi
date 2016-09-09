"""Update API Call handler for users."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId

# parse_multipart, parse_header
from cgi import escape, FieldStorage
from urllib import unquote
from boto.s3.connection import S3Connection
from boto.s3.key import Key

# from PIL
from PIL import Image
import cStringIO

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("user",)
POST_VALID_PARAMS = ("bio", "realish_name", "location", "home", 
                     "display_name", "avatar",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def adjust_image_resolution(data):
    """Given image data, shrink it to no greater than 1024 for its larger
    dimension."""
    
    inputbytes = cStringIO.StringIO(data)
    output = cStringIO.StringIO()
    
    try:
        im = Image.open(inputbytes)
        im.thumbnail((240, 240), Image.ANTIALIAS)
        # could run entropy check to see if GIF makes more sense given an item.
        im.save(output, 'JPEG')
    except IOError:
        return None
    
    return output.getvalue()

def insert_data_into_storage(name, data):
    """Given file contents, insert into S3."""

    conn = S3Connection(aws_access_key_id, aws_secret_access_key)
    b = conn.get_bucket('hyperionstorm')
    
    k = Key(b)
    k.key = "users/%s.jpg" % name

    try:
        k.set_contents_from_string(data)
    except Exception, e:
        conn.close()
        return False

    conn.close()
    return True

# Duplicate code.
def screen_name_taken(screen_name, connection):
    """Verify that a screen_name is not in the database."""

    database = connection['test']
    collection = database['users']
    
    user = collection.find_one({"screen_name" : screen_name})

    if user is None:
        return False

    return True

def update_user(user_id, update_key, update_value, connection):
    """Update the user's key with the value."""

    database = connection['test']
    collection = database['users']

    collection.update({"_id" : ObjectId(user_id)},
                      {"$set" : {update_key : update_value}})
    
    # Update the screen_name to the lowercase version of the display name.
    if (update_key == "display_name"):
        collection.update({"_id" : ObjectId(user_id)},
                          {"$set" : {"screen_name" : update_value.lower()}})
    
    return

def verify_author(author, connection):
    """Given an author id, check it."""
    
    database = connection['test']
    collection = database['users']

    try:
        post = collection.find_one({"_id" : ObjectId(author)})
    except InvalidId:
        post = None

    if post is None:
        return False

    return True

def handle_user_update(post_data):
    """Does handle multi-part data properly.

    Also, posts don't quite exist as they should."""
    
    # Determine if they have the one required parameter.
    for required in POST_REQUIRED_PARAMS:
        if required not in post_data:
            return False

    found = False
    update_key = None

    # Determine what they are updating.
    for key in post_data:
        if key in POST_VALID_PARAMS:
            update_key = key
            found = True
            break

    if not found:
        return False

    # XXX: Need to search each tag for illegal characters and also check the
    # string length, but per specific elements.

    # would like to do with Connection('localhost', 27017) as connection:...
    # where the localhost and 27017 are in a python configuration data 
    # structure.
    with Connection('localhost', 27017) as connection:
        user_id = string_from_interwebs(post_data.getfirst("user")).strip()
        
        if verify_author(user_id, connection):
            
            # Update user image with this image.
            if update_key == "avatar":

                data = post_data.getfirst(update_key)
                if data is not None:

                    data = adjust_image_resolution(data)
                    if data is not None:
                        return insert_data_into_storage(user_id, data)
            else:
                update_value = post_data.getfirst(update_key).strip()
            
                if update_key == "display_name":
                    if screen_name_taken(update_value.lower(), connection):
                        return False

                update_user(user_id, update_key, update_value, connection)
                return True

    return False

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

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
    
    # maximum file length is 1MiB
    if content_length > 1*1024*1024:
        bad_request(start_response)
        return output

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

    success = handle_user_update(post)
    if not success:
        bad_request(start_response)
        return output

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
