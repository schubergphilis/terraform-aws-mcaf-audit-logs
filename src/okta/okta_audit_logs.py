from datetime import datetime, timezone, timedelta
import requests
import pandas as pd
import json
import os
import boto3
import logging
import gzip
import shutil

logger = logging.getLogger()
logger.setLevel(logging.os.environ["log_level"].upper())

def fetch_token(token_secret_name):
    secrets_client = boto3.client("secretsmanager")
    secret_response = secrets_client.get_secret_value(
        SecretId=token_secret_name
    )

    return secret_response["SecretString"]

def handler(event, context):
    # # Create a UTC datetime object
    # utc_datetime = datetime.now(timezone.utc)
    # twenty_four_hours_ago = utc_datetime - timedelta(hours=24)

    # # Convert UTC datetime to ISO-8601 format
    # iso8601_format = twenty_four_hours_ago.isoformat("T", "milliseconds")

    # # Okta url date and time
    # okta_date_time = iso8601_format.replace("+00:00", "Z")

    # base_url = "https://cbh.okta.com/api/v1/logs?since="
    # url = base_url + okta_date_time

    # Current date in ISO format (assuming today is 2023-12-11)
    today = datetime.now()

    # Calculate yesterday's date
    yesterday = today - timedelta(days=1)

    # Create start_time and end_time variables for yesterday
    start_time = yesterday.strftime("%Y-%m-%dT00:00:00.000Z")
    end_time = yesterday.strftime("%Y-%m-%dT23:59:59.999Z")

    # Construct the URL
    url = f"https://cbh.okta.com/api/v1/logs?since={start_time}&until={end_time}&limit=1000"

    token_secret_name = os.environ["token_secret_name"]
    token = fetch_token(token_secret_name)

    # Replace with your Okta API token or authentication method
    headers = {
        "Authorization": "SSWS " + token
    }

    # Make the GET request
    response = requests.get(url, headers=headers)

    # Check if the request was successful (status code 200)
    if response.status_code == 200:
        # Parse the JSON response
        log_data = response.json()
        # Process the log data as needed
        print("Log data retrieved successfully.")
        print(log_data)
        filename = '/tmp/log_data.json'

        # Write the log_data to the file
        with open(filename, 'w') as file:
            json.dump(log_data, file, indent=4)  # You can use indent to make the JSON data more readable

        print(f"Log data has been written to {filename}")
    else:
        logging.error(f"Error: HTTP status code {response.status_code}")
        logging.error(response.text)

    df = pd.read_json('/tmp/log_data.json')
    df.to_csv('/tmp/log_file.csv')

    # Initialize the S3 client
    s3 = boto3.client('s3')
    s3_bucket_name = os.environ["logs_bucket"]

    original_filename = '/tmp/log_file.csv'

    # Path for the resulting .gz file
    gz_file_name = '/tmp/log_file.csv.gz'

    # Compressing the CSV file into a .gz file
    with open(original_filename, 'rb') as f_in:
        with gzip.open(gz_file_name, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)


    # Get the current date and time
    current_datetime = datetime.now(timezone.utc)

    # Format the date and time (e.g., YYYYMMDD_HHMMSS)
    datetime_stamp = current_datetime.strftime("%Y%m%d_%H%M%S")

    # New filename with date-time stamp
    new_filename = f"{os.path.splitext(gz_file_name)[0]}_{datetime_stamp}.csv.gz"

    # Rename the file
    os.rename(gz_file_name, new_filename)
    log_file_prefix = os.environ["file_prefix"]

    # Specify the S3 object key (file name in the bucket)
    s3_object_key = log_file_prefix + new_filename.replace("/tmp/", "")  # Customize the path as needed

    # Upload the file to the S3 bucket
    s3.upload_file(new_filename, s3_bucket_name, s3_object_key)

    # Clean up: Remove the local file if needed
    os.remove(new_filename)
    os.remove('/tmp/log_data.json')

    logging.error














    (f"Log data has been saved to '{new_filename}' and uploaded to S3 bucket '{s3_bucket_name}' with object key '{s3_object_key}'.")
