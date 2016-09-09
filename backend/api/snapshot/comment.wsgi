"""Comment API Call handler for snapshots."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote
from datetime import datetime

# author will likely come from the auth session.
# missing "data" in this list, mind you it's manually checked.
POST_REQUIRED_PARAMS = ("user", "post", "comment",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def cleanup_comment_local(comment):
    """Given a dictionary of a comment record, return a new dictionary for 
    output as JSON."""

    comm_data = comment
    comm_data["user"] = str(comm_data["user"])
    comm_data["created"] = str(comm_data["created"].ctime())
    
    del comm_data["post"]
    del comm_data["_id"] # amazingly this gets inserted.

    return comm_data

def update_post(post_id, connection):
    """Given a post id, update it's flagged."""

    database = connection['test']
    collection = database['posts']

    collection.update({"_id" : ObjectId(post_id)},
                      {"$inc" : {"comments" : 1}})

def verify_perms(author_id, post_author, connection):
    """Given the comment author and the post author, verify the comment author
    is authorized by the post author (authorizer)."""

    database = connection['test']
    collection = database['commenters']

    try:
        authorized_log = collection.find_one({"$and" : [{"authorized" : ObjectId(author_id)},
                                                        {"authorizer" : ObjectId(post_author)}]})
    except InvalidId:
        authorized_log = None

    return authorized_log

def verify_post(post_id, connection):
    """Given a post id, check it.  This is different than the others."""

    database = connection['test']
    collection = database['posts']

    try:
        post = collection.find_one({"_id" : ObjectId(post_id)})
    except InvalidId:
        post = None

    return post

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
        with Connection('localhost', 27017) as connection:
            database = connection['test']
            collection = database['comments']

            # need to wrap with try, except
            entry = collection.insert(post)

            update_post(str(post["post"]), connection)

            return cleanup_comment_local(post)

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
    comment_value = str(string_from_interwebs(query_dict["comment"][0])).strip()
    
    with Connection('localhost', 27017) as connection:
        if not verify_author(author_id, connection):
            return None

        post = verify_post(post_id, connection)
        if post is None:
            return None
        
        # I try to not use ObjectId's directly, I think in one place I do --
        # but it's very clear that this is a divergence.
        if author_id != str(post["author"]):
            if not verify_perms(author_id, str(post["author"]), connection):
                return None

        post = {"user"    : ObjectId(author_id),
                "post"    : ObjectId(post_id),
                "created" : datetime.utcnow(),
                "comment" : comment_value}

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
