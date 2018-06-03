import boto3
from os.path import basename
import zipfile
import os
import botocore
import shutil
import pathlib

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
    zipfile.ZipFile('/tmp/' + destination_file, mode='w').write('/tmp/' + original_file)


def upload_to_s3(file_name):
    s3 = boto3.resource('s3')
    s3.Object(BUCKET_NAME, file_name).put(Body=open('/tmp/' + file_name, 'rb'))

def handler(event, context):
    file_to_zip = event['Records'][0]['s3']['object']['key']
    if '.zip' in file_to_zip:
        return
    # Create needed files
    file_to_zip_with_tmp = '/tmp/' + file_to_zip
    path = pathlib.Path(file_to_zip_with_tmp)
    path.parent.mkdir(parents=True, exist_ok=True)

    download_from_s3(file_to_zip)
    zip_name = os.path.splitext(basename(file_to_zip))[0] + '.zip'
    zip_file(file_to_zip, zip_name)
    upload_to_s3(zip_name)
