import boto3
import botocore
from os.path import basename
import zipfile
import os

BUCKET_NAME = 'zip-keeper-aui-project'



def download_from_s3(file_name):
    s3 = boto3.resource('s3')
    try:
        s3.Bucket(BUCKET_NAME).download_file(file_name, '/tmp/' + file_name)
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            print("The object does not exist.")
        else:
            raise

def zip_file(original_file, destination_file):
    zf = zipfile.ZipFile('/tmp/' + destination_file, mode='w')
    if not zipfile.is_zipfile('/tmp/' + original_file):
        try:
            zf.write('/tmp/' + original_file)
        except KeyError:
            print('ERROR')
        finally:
            zf.close()

def upload_to_s3(file_name):
    s3 = boto3.resource('s3')
    s3.Object(BUCKET_NAME, file_name).put(Body=open('/tmp/' + file_name, 'rb'))

def handler(event, context):
    file_to_zip = event['Records'][0]['s3']['object']['key']
    download_from_s3(file_to_zip)
    zip_name = basename(file_to_zip)
    zip_name = os.path.splitext(zip_name)[0] + '.zip'
    zip_file(file_to_zip, zip_name)
    upload_to_s3(zip_name)
