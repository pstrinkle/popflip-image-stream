"""Join API Handler."""

from pymongo import Connection
from pymongo.errors import InvalidId
from bson.objectid import ObjectId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

POST_REQUIRED_PARAMS = ("user", "community",)
MAX_COMMUNITIES = 25

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

# db.users.update({"_id" : ObjectId("4ffb168d5e358e377900000a")},
#                 { $set : {"watched" : 0} },
#                 false,
#                 false) 
def update_involved(user, connection):
    """Increment the communities value for the user."""

    database = connection['test']
    collection = database['users']

    collection.update({"_id" : ObjectId(user)},
                      {"$inc" : {"communities" : 1}})
    
    return

def check_duplicate_community(user, community, connection):
    """User is the user id string and community will be the array."""
    
    database = connection['test']
    collection = database['communities']
    
    try:
        post = collection.find_one({"$and" : [{"user" : ObjectId(user)},
                                              {"community" : community}]})
    except InvalidId:
        post = None
    
    if post is None:
        return False
    
    return True

# XXX: Using separate connections may just be stupid and slow.
def check_count(user, connection):
    """Given an author id, check to make sure it has fewer than MAX watches."""

    database = connection['test']
    collection = database['users']

    post = collection.find_one({"_id" : ObjectId(user)})

    if post["communities"] >= MAX_COMMUNITIES:
        return True

    return False

# XXX: Use this information with check_count()
def verify_author(user, connection):
    """Given an author id, check it."""

    database = connection['test']
    collection = database['users']

    try:
        post_a = collection.find_one({"_id" : ObjectId(user)})
    except InvalidId:
        post_a = None
    
    if post_a is None:
        return False

    return True

def handle_new_community(post_data):
    """Add new community to database if input is correct."""
    
    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return None

    user = string_from_interwebs(query_dict.get("user")[0]).strip()
    community = string_from_interwebs(query_dict.get("community")[0]).strip()

    # temporary
    split_tags = [string_from_interwebs(tag).strip() for tag in community.split(",")]

    # XXX: Need to search each tag for illegal characters and also check the
    # string length.
    if len(split_tags) > 2:
        return None
    
    if split_tags[0] == split_tags[1]:
        return None
    
    with Connection('localhost', 27017) as connection:
        if not verify_author(user, connection):
            return None

        if check_count(user, connection):
            return None
    
        if check_duplicate_community(user, split_tags, connection):
            return None

        comm_link = {"user" : ObjectId(user), "community" : split_tags}

        database = connection['test']
        collection = database['communities']

        # need to wrap with try, except
        entry = collection.insert(comm_link)
    
        update_involved(user, connection)

    return {"id" : str(entry)}

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """wsgi entry point."""

    output = []
    outtype = "application/json"

    if environ['REQUEST_METHOD'] == 'GET':
        bad_request(start_response)
        return output

    # this simplifies parameter parsing.
    if environ['CONTENT_TYPE'] == 'application/x-www-form-urlencoded':
        try:
            content_length = int(environ['CONTENT_LENGTH'])
        except ValueError:
            content_length = 0
            
        # show form data as received by POST:
        post_data = environ['wsgi.input'].read(content_length)
        
        entry = handle_new_community(post_data)
        if entry is None:
            bad_request(start_response)
            return output
        
        output.append(dumps(entry, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
