"""New API Call handler for users."""

from pymongo import Connection
from datetime import datetime
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

# author will likely come from the auth session.
POST_REQUIRED_PARAMS = ("realish_name", "display_name", "email", "code",)
POST_OPTIONAL_PARAMS = ("location", "bio", "home",)

# XXX: Move into neato library.
# Need to maybe add .decode("utf8") to it.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

# Duplicate code.
def screen_name_taken(screen_name):
    """Verify that a screen_name is not in the database."""

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['users']
    
    user = collection.find_one({"screen_name" : screen_name})

    connection.close()

    if user is None:
        return False

    return True

def insert_post_into_db(post):
    """Given a post dictionary, insert it into database collection for posts."""
    
    if post is not None:
        connection = Connection('localhost', 27017)
        database = connection['test']
        collection = database['users']

        # need to wrap with try, except
        entry = collection.insert(post)
        
        connection.close()

        return {"id" : str(entry)}
    
    return None

def handle_new_user(post_data):
    """Does not handle multi-part data properly.
    
    Also, posts don't quite exist as they should."""
    
    # likely throws an exception on parse error.
    query_dict = parse_qs(post_data, keep_blank_values=True)

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return None
    
    try:
        value = int(string_from_interwebs(query_dict["code"][0]))
    except ValueError:
        return None
    
    if value != 98098098098:
        return None
    
    display_name = string_from_interwebs(query_dict.get("display_name")[0]).strip()
    screen_name = display_name.lower()

    if screen_name_taken(screen_name):
        return None

    user = {"premium" : False,
            "badges" : [],
            "flagged" : 0,
            "watching" : 0,
            "watched" : 0,
            "communities" : 0,
            "private" : False}

    user["bio"] = string_from_interwebs(query_dict.get("bio", [""])[0]).strip()
    user["realish_name"] = string_from_interwebs(query_dict.get("realish_name")[0]).strip()
    user["display_name"] = display_name
    user["screen_name"] = screen_name
    user["created"] = datetime.utcnow()
    user["location"] = string_from_interwebs(query_dict.get("location", [""])[0]).strip()
    user["email"] = string_from_interwebs(query_dict.get("email")[0]).strip()
    user["home"] = string_from_interwebs(query_dict.get("home", [""])[0]).strip()

    return user
    
def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """Entry point for all wsgi applications."""

    output = []

    ##### parameters are never safe
    try:
        content_length = int(environ['CONTENT_LENGTH'])
    except ValueError:
        content_length = 0

    if environ['CONTENT_TYPE'] != 'application/x-www-form-urlencoded':
        bad_request(start_response)
        return output

    post_data = environ['wsgi.input'].read(content_length)

    entry = insert_post_into_db(handle_new_user(post_data))
    if entry is None:
        bad_request(start_response)
        return output

    output.append(dumps(entry, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'), # application/json
                        ('Content-Length', str(output_len))])

    return output
