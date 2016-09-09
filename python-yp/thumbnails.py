
from boto.s3.connection import S3Connection
from boto.s3.key import Key
from PIL import Image
import cStringIO

def main():

    conn = S3Connection(aws_access_key_id, aws_secret_access_key)
    bucket = conn.get_bucket('hyperionstorm')

    files = bucket.list("data/")

    for file_key in files:
        if ".jpg" not in file_key.key:
            continue

        if "tiny" in file_key.key:
            continue

        print "Processing: %s" % file_key.key

        output_tiny = cStringIO.StringIO()

        im2 = Image.open(cStringIO.StringIO(file_key.get_contents_as_string()))
        im2.thumbnail((120, 120), Image.ANTIALIAS)
        im2.save(output_tiny, 'JPEG')

        k_tiny = Key(bucket)
        k_tiny.key = "data/%s_tiny.jpg" % file_key.key.replace("data/","").replace(".jpg","")
        k_tiny.set_contents_from_string(output_tiny.getvalue())

    conn.close()

if __name__ == "__main__":
    main()
