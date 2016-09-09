"""Query API Call handler for users."""

from bson.objectid import ObjectId
from pymongo import Connection
from pymongo.errors import InvalidId
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

QUERY_INVALID = 0
QUERY_COMMUNITY = 1
QUERY_WATCHLIST = 2
QUERY_FAVORITES = 3

POST_REQUIRED_PARAMS = ("query", "id",)

# this won't work quite right when we transition to handle other queries, 
# likely this will be refactored into a class that can support building complex 
# queries.
SUPPORTED_QUERIES = {"community" : QUERY_COMMUNITY,
                     "watchlist" : QUERY_WATCHLIST,
                     "favorites" : QUERY_FAVORITES}

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

def cleanup_community(community):
    """Given a dictionary of a community, return a new dictionary for output as
    JSON."""

    return community["community"]

def cleanup_watchlist(watch):
    """Given a dictionary of a watchlist, return a new dictionary for output as
    JSON."""

    return str(watch["watched"])

def cleanup_favorite(favorite):
    """Given a dictionary of a favorite item, return a str."""
    
    return str(favorite["post"])

def validate_query_handler(query_string):
    """Verify the input query is some level of valid, right now it does not 
    check the value sent, just the key.

    Currently only support one key, value pair -- but does verify this is 
    supplied."""

    # likely throws an exception on parse error.
    query_dict = parse_qs(query_string, keep_blank_values=True)

    if len(query_dict) != 2:
        return QUERY_INVALID, None

    for required in POST_REQUIRED_PARAMS:
        if required not in query_dict:
            return QUERY_INVALID, None

    query_type = string_from_interwebs(query_dict["query"][0]).strip()

    if query_type not in SUPPORTED_QUERIES:
        return QUERY_INVALID, None

    return SUPPORTED_QUERIES[query_type], query_dict

def handle_community_query(query_dict):
    """Query the localhost mongodb instance for communities.
    
    Always escape values taken from query_dict."""

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['communities']
    
    user_id = string_from_interwebs(query_dict["id"][0]).strip()
    
    communities = []

    # this should not except
    try:
        for post in collection.find({"user" : ObjectId(user_id)}):
            communities.append(cleanup_community(post))
    except InvalidId:
        pass

    connection.close()

    return communities

def handle_watchlist_query(query_dict):
    """Query the localhost mongodb instance for watchlist.
    
    Always escape values taken from query_dict."""

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['watches']
    
    user_id = string_from_interwebs(query_dict["id"][0]).strip()
    
    watches = []

    # this should not except
    try:
        for post in collection.find({"author" : ObjectId(user_id)}):
            watches.append(cleanup_watchlist(post))
    except InvalidId:
        pass

    connection.close()

    return watches

def handle_favorite_query(query_dict):
    """Query the localhost mongod instance for favorites."""

    connection = Connection('localhost', 27017)
    database = connection['test']
    collection = database['favorites']
    
    user_id = string_from_interwebs(query_dict["id"][0]).strip()
    
    favorites = []

    # this should not except
    try:
        for post in collection.find({"user" : ObjectId(user_id)}):
            favorites.append(cleanup_favorite(post))
    except InvalidId:
        pass

    connection.close()

    return favorites

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

    query_type, query_dict = validate_query_handler(environ['QUERY_STRING'])

    if query_type == QUERY_INVALID:
        bad_request(start_response)
        return output

    results = None

    # I could handle this with a simple call table in a dictionary.
    if query_type == QUERY_COMMUNITY:
        results = handle_community_query(query_dict)
    elif query_type == QUERY_WATCHLIST:
        results = handle_watchlist_query(query_dict)
    elif query_type == QUERY_FAVORITES:
        results = handle_favorite_query(query_dict)

    # when given an invalid query parameter it returns None, otherwise it 
    # returns an empty array (which is a valid response).
    if results is None:
        bad_request(start_response)
        return output

    output.append(dumps(results, indent=4))

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', 'application/json'),
                        ('Content-Length', str(output_len))])

    return output

