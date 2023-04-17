import json
import urllib3
import boto3
import awswrangler as wr
import os
from datetime import timezone
import datetime

im_hook = 'https://hooks.slack.com/services/'
secret_name = "slack-secret"
region_name = "us-east-1"


def produce_message(message):
    http = urllib3.PoolManager()
    msg = {
        # The channel must be created in Slack first
        "channel": "##etl-logs",
        "username": "Lambda CSV ingestion",
        "text": message,
    }
    encoded_msg = json.dumps(msg).encode("utf-8")
    http.request("POST", get_secret(), body=encoded_msg)
    print(message)

def get_secret():
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = im_hook + json.loads(get_secret_value_response['SecretString']).get('slack-secret')
    except Exception as error:
        print(f"Can not retrieve secret from vault. Error: n\ {error}")
    
    return secret

def lambda_handler(event, context):
    # Create metadata. 
    dt = datetime.datetime.now(timezone.utc)
    utc_timestamp = datetime.datetime.now(timezone.utc)
    ingestion_date = str(utc_timestamp.date().strftime('%Y-%m-%d'))
    
    try:
        s3 = boto3.client('s3')
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        s3_csv_file_key = event['Records'][0]['s3']['object']['key']
        print('File Loaded')
    except Exception as error:
        produce_message(f"Error while ingesting files. Error: \n {error}")

    destination_bucket = 'data-feeds-discovery-5'
    destination_path = 'csv-ingestion/' + ingestion_date
    file_name = os.path.basename(s3_csv_file_key).replace('.csv','.parquet')

    csv_file = 's3://' + source_bucket + '/' + s3_csv_file_key
    parquet_file =  's3://' + destination_bucket + '/' + destination_path + '/' + file_name

    # Accessing and modify data
    try:
        data = wr.s3.read_csv(csv_file)
    except Exception as error:
        produce_message(f"Pandas could not load the file. Error: \n {error}")

    data['upload_at']= utc_timestamp
    data.dropna()
    row_count= (len(data.index))

    # Writting data
    try:
        wr.s3.to_parquet(data, parquet_file)
    except Exception as error:
        produce_message(f"Could not write file {file_name}. Error \n: {error}")

    produce_message(f"{file_name} ingested with {row_count} rows processed.")