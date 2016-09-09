"""Get API Call handler for users."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

GET_VALID_PARAMS = ("id", "screen_name",)
POST_REQUIRED_PARAMS = ("id", "requester",)

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""

    return escape(unquote(input_value))

def validate_post_handler(query_string):
    """Validate the request is valid."""

    query_dict = parse_qs(query_string, keep_blank_values=True)

    # has id/screen_name and full.
    if len(query_dict) > 3:
        return None

    # walk through parameters and check to see that least one input is valid.
    # this is different because it's checking what is required.
    for param in POST_REQUIRED_PARAMS:
        if param not in query_dict:
            return None

    return query_dict

def validate_get_handler(query_string):
    """Validate the request is simply id=val."""
    
    query_dict = parse_qs(query_string, keep_blank_values=True)
    
    # has id/screen_name and full.
    if len(query_dict) > 2:
        return None

    # walk through parameters and check to see that least one input is valid.
    for param in GET_VALID_PARAMS:
        if param in query_dict:
            return query_dict

    return None

def cleanup_watch(watch):
    """Given a dictionary of a watch, return a new dictionary for output as
    JSON.
    
    This is not the standard cleanup function, because we know who the author 
    is."""

    return str(watch["watched"])

######### This code is now in two files; need to move into library
def cleanup_user(user, same_person):
    """Given a dictionary of a user, return a new dictionary for output as 
    JSON."""
    
    user_data = user
    user_data["id"] = str(user["_id"])
    user_data["created"] = str(user["created"].ctime())
    
    if not same_person:
        del user_data["email"]
    
    del user_data["_id"]
    
    return user_data

def cleanup_favorite(favorite):
    """Given a dictionary of a favorite record, return a new dictionary for 
    output as JSON."""
    
    return str(favorite["post"])

def handle_favorites(connection, user):
    """Return an array of favorites for the author."""
    
    favorites = []
    
    database = connection['test']
    collection = database['favorites']
    
    for favorite in collection.find({"user" : ObjectId(user)}):
        favorites.append(cleanup_favorite(favorite))

    return favorites

def handle_watches(connection, author):
    """Return an array of watches for the author."""
    
    database = connection['test']
    collection = database['watches']
    
    watches = []

    # this should not except
    for post in collection.find({"author" : ObjectId(author)}):
        watches.append(cleanup_watch(post))
    
    return watches

def handle_authorized(connection, requester, user_id):
    """Return boolean if the requester is authorized against user_id.
    
    Here, authorized is requester and authorizer is user_id."""
    
    # why check.
    if requester == user_id:
        return True
    
    database = connection['test']
    collection = database['commenters'] # I think this is spelled incorrectly.

    check_comm_auth = None

    try:
        check_comm_auth = collection.find_one({"$and" : [{"authorizer" : ObjectId(user_id)},
                                                         {"authorized" : ObjectId(requester)}]})
    except InvalidId:
        return False
    
    # if there is an entry then you're authorized.
    if check_comm_auth is not None:
        return True
    
    return False

def handle_post(query_dict):
    """Return a cleaned copy of the JSON."""    
    
    output = []
    
    if query_dict is None:
        return output

    #only handles first
    full_return = False
    same_person = False

    # need they do more than simply mention it.
    if "full" in query_dict:
        #full_return = bool(escape(query_dict["full"][0]))
        if str(string_from_interwebs(query_dict["full"][0])) == "true":
            full_return = True

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['users']

        user = None

        # user_id is whose info you're requesting
        user_id = str(string_from_interwebs(query_dict["id"][0]))
        # requester is the person requesting the information (obviously)
        requester = str(string_from_interwebs(query_dict["requester"][0]))
        
        if user_id == requester:
            same_person = True

        # overwrite user variable.
        try:
            user = collection.find_one({"_id" : ObjectId(user_id)})
        except InvalidId:
            pass

        if user is not None:
            user["watches"] = handle_watches(connection, user_id)

            if full_return:
                user["favorites"] = handle_favorites(connection, user_id)

            # Check if requester is authorized against user_id.
            user["authorized"] = handle_authorized(connection, requester, user_id)
            # Check if user_id is authorized against requester.
            user["authorized_back"] = handle_authorized(connection, user_id, requester)

            output.append(dumps(cleanup_user(user, same_person), indent=4))

    return output

def handle_get(query_dict):
    """Return a cleaned copy of the JSON."""    
    
    output = []
    
    if query_dict is None:
        return output

    #only handles first
    full_return = False

    # need they do more than simply mention it.
    if "full" in query_dict:
        #full_return = bool(escape(query_dict["full"][0]))
        if str(string_from_interwebs(query_dict["full"][0])) == "true":
            full_return = True

    with Connection('localhost', 27017) as connection:
        database = connection['test']
        collection = database['users']

        user = None

        if "screen_name" in query_dict:
            screen_name = str(string_from_interwebs(query_dict["screen_name"][0])).lower()
            user = collection.find_one({"screen_name" : screen_name})
            
            if user is None:
                return output
            
            user_id = str(user["_id"])
        else:
            user_id = str(string_from_interwebs(query_dict["id"][0]))

        # overwrite user variable.
        try:
            user = collection.find_one({"_id" : ObjectId(user_id)})
        except InvalidId:
            pass

        if user is not None:
            user["watches"] = handle_watches(connection, user_id)

            if full_return:
                user["favorites"] = handle_favorites(connection, user_id)

            output.append(dumps(cleanup_user(user, False), indent=4))

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
    results = []

    if environ['REQUEST_METHOD'] == 'POST':
        try:
            content_length = int(environ['CONTENT_LENGTH'])
        except ValueError:
            content_length = 0
            
        # show form data as received by POST:
        post_data = environ['wsgi.input'].read(content_length)
        
        results = handle_post(validate_post_handler(post_data))
    elif environ['REQUEST_METHOD'] == 'GET':
        results = handle_get(validate_get_handler(environ['QUERY_STRING']))

        # this should only ever have one element in the array.
    if len(results) != 1:
        bad_request(start_response)
        return output

    output.extend(results)

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output
