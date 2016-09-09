"""Management Interface; just dumps the databases."""

import pymongo
from cgi import escape
from urlparse import parse_qs
from json import dumps
from urllib import unquote

# XXX: Move into neato library.
def string_from_interwebs(input_value):
    """Given a string from the query dictionary string thing; make it clean."""
    
    return escape(unquote(input_value))

######### This code is now in two files; need to move into library
def cleanup_post(post):
    """Given a dictionary of a post, return a new dictionary for output as 
    JSON."""
    
    post_data = post
    post_data["id"] = str(post["_id"])
    post_data["author"] = str(post["author"])
    # x = datetime.datetime(2012,04,01,0,0) 
    # y = datetime.datetime(1970,1,1)
    # (x - y).total_seconds()
    post_data["created"] = str(post["created"].ctime())
    del post_data["_id"]
    
    if "reply_to" in post:
        post_data["reply_to"] = str(post["reply_to"])

    if "repost_of" in post:
        post_data["repost_of"] = str(post["repost_of"])
    
    return post_data

def cleanup_comment(comment):
    """Given a dictionary of a comment record, return a new dictionary for 
    output as JSON."""

    comm_data = comment
    comm_data["id"] = str(comm_data["_id"])
    comm_data["user"] = str(comm_data["user"])
    comm_data["post"] = str(comm_data["post"])
    comm_data["created"] = str(comm_data["created"].ctime())
    del comm_data["_id"]

    return comm_data

def cleanup_authorizer(authorize):
    """Given a dictionary of a comment authorizer record, return a new 
    dictionary for output as JSON."""

    auth_data = authorize
    auth_data["id"] = str(auth_data["_id"])
    auth_data["authorizer"] = str(auth_data["authorizer"])
    auth_data["authorized"] = str(auth_data["authorized"])
    del auth_data["_id"]

    return auth_data

def cleanup_watch(watch):
    """Given a dictionary of a watch record, return a new dictionary for output
    as JSON."""
    
    watch_data = watch
    watch_data["id"] = str(watch["_id"])
    watch_data["author"] = str(watch["author"])
    watch_data["watched"] = str(watch["watched"])
    del watch_data["_id"]
    
    return watch_data

def cleanup_favorite(favorite):
    """Given a dictionary of a favorite record, return a new dictionary for
    output as JSON."""
    
    favorite_data = favorite
    favorite_data["user"] = str(favorite["user"])
    favorite_data["post"] = str(favorite["post"])
    favorite_data["id"] = str(favorite["_id"])
    del favorite_data["_id"]
    
    return favorite_data

######### This code is now in two files; need to move into library
def cleanup_user(user):
    """Given a dictionary of a user, return a new dictionary for output as 
    JSON."""
    
    user_data = user
    user_data["id"] = str(user["_id"])
    user_data["created"] = str(user["created"].ctime())
    del user_data["_id"]
    del user_data["email"] # as we start having beta-testers we need to start hiding private information.
    
    return user_data

def cleanup_community(community):
    """Given a dictionary of a community, return a new dictionary for output as
    JSON."""
    
    comm_data = community
    comm_data["id"] = str(community["_id"])
    comm_data["user"] = str(community["user"])
    del comm_data["_id"]
    
    return comm_data

def cleanup_report(report):
    """Given a dictionary of a report, return a new dictionary for output as
    JSON."""
    
    report_data = report
    report_data["id"] = str(report["_id"])
    report_data["user"] = str(report["user"])
    report_data["post"] = str(report["post"])
    del report_data["_id"]
    
    return report_data

def get_comments(connection):
    """Just dump all comments as json."""

    posts = []

    database = connection['test']
    collection = database['comments']

    for post in collection.find():
        posts.append(cleanup_comment(post))

    return posts

def get_commenters(connection):
    """Just dump all commenter records and all their components as json."""

    posts = []

    database = connection['test']
    collection = database['commenters']

    for post in collection.find():
        posts.append(cleanup_authorizer(post))

    return posts

def get_posts(connection):
    """Just dump all posts and all their components as json."""

    posts = []

    database = connection['test']
    collection = database['posts']
    
    for post in collection.find():
        posts.append(cleanup_post(post))

    return posts

def get_watches(connection):
    """Jump dump all watches and all their components as json."""

    watches = []
    
    database = connection['test']
    collection = database['watches']
    
    for watch in collection.find():
        watches.append(cleanup_watch(watch))

    return watches

def get_favorites(connection):
    """Just dump all favorites and their components as json."""

    favorites = []
    
    database = connection['test']
    collection = database['favorites']
    
    for favorite in collection.find():
        favorites.append(cleanup_favorite(favorite))

    return favorites

def get_users(connection):
    """Just dump all users and all their components as json."""

    users = []

    database = connection['test']
    collection = database['users']
    
    for user in collection.find():
        users.append(cleanup_user(user))

    return users

def get_communities(connection):
    """Just dump all community links and all their components as json."""
    
    communities = []
    
    database = connection['test']
    collection = database['communities']
    
    for community in collection.find():
        communities.append(cleanup_community(community))
    
    return communities


def get_reports(connection):
    """Just dump all community links and all their components as json."""
    
    reports = []
    
    database = connection['test']
    collection = database['reports']
    
    for report in collection.find():
        reports.append(cleanup_report(report))
    
    return reports

def handle_admin(query_dict):
    """Handle the admin query."""

    try:
        key = int(string_from_interwebs(query_dict["code"][0]))
    except KeyError:
        return None

    if key != 58780932341:
        return None

    connection = pymongo.Connection('localhost', 27017)

    request = None
    if "request" in query_dict:
        request = string_from_interwebs(query_dict["request"][0])

    if request == "commenters":
        data = {"commenters" : get_commenters(connection)}
    elif request == "comments":
        data = {"comments" : get_comments(connection)}
    elif request == "users":
        data = {"users" : get_users(connection)}
    elif request == "posts":
        data = {"posts" : get_posts(connection)}
    elif request == "watches":
        data = {"watches" : get_watches(connection)}
    elif request == "favorites":
        data = {"favorites" : get_favorites(connection)}
    elif request == "communities":
        data = {"communities" : get_communities(connection)}
    elif request == "reports":
        data = {"reports" : get_reports(connection)}
    else:
        data = {"users" : get_users(connection),
                "posts" : get_posts(connection),
                "watches" : get_watches(connection),
                "favorites" : get_favorites(connection),
                "communities" : get_communities(connection),
                "reports" : get_reports(connection),
                "commenters" : get_commenters(connection),
                "comments" : get_comments(connection)}

    connection.close()

    return dumps(data, indent=4)

def bad_request(start_response):
    """Just does the same thing, over and over -- returns bad results.."""

    output_len = 0
    start_response('400 Bad Request',
                   [('Content-type', 'text/html'),
                        ('Content-Length', str(output_len))])

def application(environ, start_response):
    """wsgi entry point."""

    output = []
    outtype = "text/html"

    if environ['REQUEST_METHOD'] == 'GET':
        output.append('<form method="post">')
        output.append('<input type="text" name="code" value="code"><br>')
        output.append('<input type="text" name="request" value="request"><br>')
        output.append('<input type="submit">')
        output.append('</form>')
    elif environ['REQUEST_METHOD'] == 'POST':
        # this simplifies parameter parsing.
        if environ['CONTENT_TYPE'] == 'application/x-www-form-urlencoded':
            try:
                content_length = int(environ['CONTENT_LENGTH'])
            except ValueError:
                content_length = 0
            
            # show form data as received by POST:
            post_data = environ['wsgi.input'].read(content_length)

            # likely throws an exception on parse error.
            query_dict = parse_qs(post_data, keep_blank_values=True)
            
            if len(query_dict) > 0:
                results = handle_admin(query_dict)

                output.append(results)

            outtype = "application/json"

    # send results
    output_len = sum(len(line) for line in output)
    start_response('200 OK',
                   [('Content-type', outtype),
                        ('Content-Length', str(output_len))])

    return output
