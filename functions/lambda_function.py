import boto3
import logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
client = boto3.client("s3")

def lambda_handler(event, context):
    get_bucket_content(key="s3_test.json", bucketname="elitech")    


def get_bucket_content(key, bucketname):
    response = client.get_object(
        Bucket=bucketname,
        Key=key,
        )
    s3_data = response['Body'].read().decode('utf-8')  
    logger.info(s3_data) 
   



    