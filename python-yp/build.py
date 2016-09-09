"""This script attempts to build the database with pre-defined values."""

import yawningpanda as yp
import os
import random

def main():
    """Run through a series of pre-defined commits."""
    
    # First create some users; then query the system to find out who we have to
    # work with, then walk through the list of images in the test-img directory
    # and create posts from various combinations of things.
    
    img_base = "test-img"
    
    random.seed()
    api = yp.Api()
    images = [img for img in os.listdir(img_base) if img.endswith(".jpg")]
    
    users = random.randint(2, 15)
    
    for i in range(1, users+1):
        #                realish_name, display_name, email
        api.create_user("user%d" % i, "user %d" % i, "user%d@users.com" % i)
    
    state = api.admin("users")
    user_list = state["users"]
    tag_list = ("jack", "eskimo", "cat", "couch", "sleepy", "attack")
    post_ids = []
    
    # build posts
    for img in images:
        author = user_list[random.randint(0, len(user_list)-1)]["id"]
        tag_count = random.randint(1, 3)
        image = os.path.join(img_base, img)
        
        tags = []
        for i in range(tag_count):
            tags.append(tag_list[random.randint(0, len(tag_list)-1)])
        
        new_id = api.create_post(
                                 author,
                                 tags,
                                 open(image, "rb"))
        
        print "created: %s" % new_id
        
        post_ids.append(new_id["id"])
    
    # build replies
    for i in range(random.randint(1, len(post_ids) / 2)):
        source_id = post_ids[random.randint(0, len(post_ids)-1)]
        author = user_list[random.randint(0, len(user_list)-1)]["id"]
        tag_count = random.randint(1, 3)
        
        tags = []
        for i in range(tag_count):
            tags.append(tag_list[random.randint(0, len(tag_list)-1)])
        
        image = os.path.join(img_base, images[random.randint(0, len(images)-1)])

        print "replying to: %s" % source_id
        print api.reply_post(source_id, author, tags, open(image, "rb"))
    
    # add random watch relationships.
    
    # add random posts as enjoyed.
    
    # add random posts as favorites.
    
    # add random communities joined.
    
    # add us
    #               realish_name, display_name
    api.create_user("Nancy Trinkle", "umanyannya", "nancy@hyperionstorm.com")
    api.create_user("Jim Smyth", "Jimux", "jim@hyperionstorm.com")
    api.create_user("Jeff Liott", "DoctorPOM", "jeff@hyperionstorm.com")
    api.create_user("Jeff Liott, Radiant Studios",
                    "Radiant",
                    "jeff@hyperionstorm.com")
    api.create_user("Patrick Trinkle",
                    "ProfoundAlias",
                    "patrick@hyperionstorm.com")
    api.create_user("John Cavallo", "Da", "fake@email.com")

if __name__ == "__main__":
    main()
