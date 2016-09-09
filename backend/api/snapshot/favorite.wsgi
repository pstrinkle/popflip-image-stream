"""Favorite API Call handler for snapshots."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("user", "post",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def update_post(post_id, connection):
    """Given a post id, update it's flagged."""

    database = connection['test']
    collection = database['posts']

    collection.update({"_id" : ObjectId(post_id)},
                      {"$inc" : {"enjoyed" : 1}})

def check_enjoy(author_id, post_id, connection):
    """Given an author and a post, check to see if they already marked it as
    enjoyed.  At first, this check seemed like a waste, but why not."""

    database = connection['test']
    collection = database['favorites']

    # need to wrap with try, except
    try:
        post = collection.find_one({"$and" : [{"user" : ObjectId(author_id)},
                                              {"post" : ObjectId(post_id)}]})
    except InvalidId:
        post = None

    return post

def verify_post(post_id, connection):
    """Given a post id, check it."""

    database = connection['test']
    collection = database['posts']

    try:
        post = collection.find_one({"_id" : ObjectId(post_id)})
    except InvalidId:
        post = None

    if post is None:
        return False

    return True

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

def insert_post_into_db(post):
    """Given a post dictionary, insert it into database collection for posts."""
    
    if post is not None:
        connection = Connection('localhost', 27017)
        database = connection['test']
        collection = database['favorites']

        # need to wrap with try, except
        entry = collection.insert(post)
        
        update_post(str(post["post"]), connection)
        
        connection.close()
        
        return {"id" : str(entry)}
    
    return None

def handle_new_post(query_dict):
    """Does not handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""
    
    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return None

    # not yet safe to use.
    post_id = str(string_from_interwebs(query_dict["post"][0])).strip()
    author_id = str(string_from_interwebs(query_dict["user"][0])).strip()
    
    with Connection('localhost', 27017) as connection:
        if not verify_author(author_id, connection):
            return None

        if not verify_post(post_id, connection):
            return None

        if check_enjoy(author_id, post_id, connection) is not None:
            return None

        post = {"user" : ObjectId(author_id), "post" : ObjectId(post_id)}

    return post
    
def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output = []
    output_len = sum(len(line) for line in output)
    start_response('400 Bad Request',
                   [('Content-type', 'application/json'),
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
        content_length = 0
    
    post_data = environ['wsgi.input'].read(content_length)

    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    processed_post = handle_new_post(query_dict)
    if processed_post is None:
        return bad_request(start_response)

    entry = insert_post_into_db(processed_post)
    if entry is None:
        return bad_request(start_response)

    output.append(dumps(entry, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
