"""Repost API Call handler for snapshots."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from datetime import datetime
from cgi import escape, FieldStorage
from json import dumps
from urllib import unquote

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("tags", "author", "code", "repost_of")
POST_OPTIONAL_PARAMS = ("location",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def update_post(connection, repost_of):
    """Given a post id, update it's num_replies."""

    database = connection['test']
    collection = database['posts']

    collection.update({"_id" : ObjectId(repost_of)},
                      {"$inc" : {"num_reposts" : 1}})

def verify_post(connection, post_id):
    """Given a post id, check it."""

    database = connection['test']
    collection = database['posts']

    try:
        post = collection.find_one({"_id" : ObjectId(post_id)})
    except InvalidId:
        post = None
    
    return post

def verify_author(connection, author):
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

def insert_post_into_db(connection, post):
    """Given a post dictionary, insert it into database collection for posts."""
    
    if post is not None:
        database = connection['test']
        collection = database['posts']

        # need to wrap with try, except
        entry = collection.insert(post)

        return {"id" : str(entry)}
    
    return None

def handle_new_post(post_data, user_agent, remote_addr):
    """Does not handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""
    
    for required in POST_REQUIRED_PARAMS:
        if required not in post_data:
            return None

    try:
        value = int(string_from_interwebs(post_data.getfirst("code", "")))
    except ValueError:
        return None
    
    if value != 98098098098:
        return None

    # not yet safe to use.
    location = post_data.getfirst("location", "")
    tags = string_from_interwebs(post_data.getfirst("tags"))    
    author = post_data.getfirst("author")
    
    split_tags = [string_from_interwebs(tag).strip().lower() for tag in tags.split(",")] # temporary
    
    if len(split_tags) > 3:
        return None
    
    author_id = string_from_interwebs(author).strip()
    
    with Connection('localhost', 27017) as connection:
        if not verify_author(connection, author_id):
            return None

        repost_of = string_from_interwebs(post_data.getfirst("repost_of"))
    
        original_post = verify_post(connection, repost_of)
    
        if original_post is None:
            return None
    
        if original_post["tags"] == split_tags:
            return None
        
        file_name = ""
        
        if "repost_of" in original_post:
            file_name = original_post["file"]
        else:
            file_name = str(original_post["_id"])

        # if reply then it's verified.
        # XXX: I need to make a standard object structure for this, so that I don't 
        # have to update separate things.
    
        post = {"viewed"       : 0,
                "comments"     : 0,
                "flagged"      : 0,
                "disliked"     : 0,
                "enjoyed"      : 0,
                "num_replies"  : 0,
                "num_reposts"  : 0,
                "content-type" : "image", # need to pull this from the mime lookup
                "file"         : file_name,
                "user_agent"   : user_agent,
                "remote_addr"  : remote_addr,
                "created"      : datetime.utcnow(),
                "location"     : string_from_interwebs(location).strip(),
                "author"       : ObjectId(author_id),
                "repost_of"    : ObjectId(repost_of),
                "tags"         : split_tags}

        update_post(connection, repost_of)

        entry = insert_post_into_db(connection, post)

    return entry
    
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
        return bad_request(start_response)

    ##### parameters are never safe
    try:
        content_length = int(environ['CONTENT_LENGTH'])
    except ValueError:
        return bad_request(start_response)
    
    user_agent = environ.get('HTTP_USER_AGENT', '')
    remote_addr = environ.get('REMOTE_ADDR', '')
    
    # add CONTENT_TYPE check
    # FieldStorage is not the best solution because it reads the entire thing
    # into memory; what I need to do is get parse_headres and parse_multipart
    # working.
    #
    # change from FieldStorage to something faster down the road; albeit that
    # may only be an issue with create(); because it is far slower than a more
    # raw method.
    post_env = environ.copy()
    post_env['QUERY_STRING'] = ''
    post = \
        FieldStorage(
                     fp=environ['wsgi.input'],
                     environ=post_env,
                     keep_blank_values=True)

    processed_post = handle_new_post(post, user_agent, remote_addr)
    
    if processed_post is None: # if data is fine, processed_post is fine.
        return bad_request(start_response)

    output.append(dumps(processed_post, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
