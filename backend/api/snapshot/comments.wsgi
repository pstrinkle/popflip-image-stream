"""Comment API Call handler for snapshots."""

from pymongo import Connection
from pymongo import DESCENDING
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

def cleanup_comment(comment):
    """Given a dictionary of a comment record, return a new dictionary for 
    output as JSON."""

    comm_data = comment
    comm_data["user"] = str(comm_data["user"])
    comm_data["created"] = str(comm_data["created"].ctime())
    del comm_data["_id"]
    del comm_data["post"]

    return comm_data

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

def handle_comments_request(query_dict):
    """Does not handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return None

    # not yet safe to use.
    post_id = str(string_from_interwebs(query_dict["post"][0])).strip()
    author_id = str(string_from_interwebs(query_dict["user"][0])).strip()

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['comments']

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

        posts = []

        try:
            for comment in collection.find({"post" : ObjectId(post_id)}).sort("created", DESCENDING):
                posts.append(cleanup_comment(comment))
        except InvalidId:
            posts = None

    return posts
    
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

    processed_list = handle_comments_request(query_dict)
    if processed_list is None:
        return bad_request(start_response)

    output.append(dumps(processed_list, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
