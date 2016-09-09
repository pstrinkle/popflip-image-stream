"""Login API Call handler for users."""

from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def validate_get_handler(query_string):
    """Validate the request is simply id=val."""
    
    query_dict = parse_qs(query_string, keep_blank_values=True)
    
    if len(query_dict) > 2:
        return None

    if "screen_name" not in query_dict:
        return None

    return query_dict

######### This code is now in two files; need to move into library
def cleanup_user(user):
    """Given a dictionary of a user, return a new dictionary for output as 
    JSON."""
    
    return {"id" : str(user["_id"])}

def handle_get(query_dict):
    """Return a cleaned copy of the JSON."""    
    
    output = []
    
    if query_dict is None:
        return output

    #only handles first
    try:
        screen_name = str(string_from_interwebs(query_dict["screen_name"][0])).lower()
    except ValueError:
        return output

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['users']
    
    user = None
    
    try:
        user = collection.find_one({"screen_name" : screen_name})
    except InvalidId:
        pass
    
    if user is not None:
        output.append(dumps(cleanup_user(user), indent=4))

    connection.close()

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

    if environ['REQUEST_METHOD'] == 'POST':
        bad_request(start_response)
        return output

    query_dict = validate_get_handler(environ['QUERY_STRING'])

    results = handle_get(query_dict)

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
