import boto3
import compress_json
import datetime
import json
import os
import requests
import time
import random


def uniqueid():
    seed = random.getrandbits(32)

    while True:
        yield seed
        seed += 1


def fetch_token(token_secret_name):
    secrets_client = boto3.client("secretsmanager")
    secret_response = secrets_client.get_secret_value(
        SecretId=token_secret_name
    )

    return secret_response["SecretString"]


def handler(event, context):

    token_secret_name = os.environ["token_secret_name"]
    token = fetch_token(token_secret_name)

    bucket = os.environ["logs_bucket"]
    initial_url = os.environ["logs_url"]
    queue_url = os.environ["queue_url"]
    log_file_prefix = os.environ["file_prefix"]

    request_headers = {
        "Content-Type": "application/json",
        "Authorization": 'Bearer %s' % token
    }

    url = initial_url
    created = datetime.date.today() - datetime.timedelta(days=1)
    params = {}
    log_date = created.strftime("%Y-%m-%d")
    page = 1
    total_pages = 1

    unique_sequence = uniqueid()

    sqs = boto3.client("sqs")

    # Lambda is triggered from cloudwatch events. We should start the process
    # using initial_url
    if "source" in event and event["source"] == "aws.events":

        # initial message to begin everything
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps({
                "log_date": log_date,
                "page": page,
                "total_pages": total_pages,
                "operation": "extract_init"
            })
        )

        return "Initial message sent"

    elif "Records" in event:

        message = event["Records"][0]
        body = json.loads(message["body"])
        log_date = body["log_date"]
        page = body["page"]
        total_pages = body["total_pages"]
        operation = body["operation"]

        if operation == "extract_init" or operation == "extract_continue":

            # this call is only to fetch pagination and setup
            # extraction in parallel processes
            if operation == "extract_init":
                params = {"since": log_date}
                response = requests.get(
                    url,
                    headers=request_headers,
                    params=params
                )
                data = response.json()
                pagination = data["pagination"]
                total_pages = pagination["total_pages"]

            sqs_pages = []
            index = 0

            for index in range(9):
                if (index + page <= total_pages):
                    # we will process these pages individually
                    sqs_pages.append({
                        "Id": str(next(unique_sequence)),
                        "MessageBody": json.dumps({
                            "page": index + page,
                            "total_pages": total_pages,
                            "operation": "extract",
                            "log_date": log_date
                        })
                    })

            # batch only support 10 messages at a time so we will
            # setup next 10 pages in a separate call. This also makes
            # sure that each process is short and does one thing properly
            if index + page < total_pages:
                sqs_pages.append({
                        "Id": str(next(unique_sequence)),
                        "MessageBody": json.dumps({
                            "page": index + page + 1,
                            "total_pages": total_pages,
                            "operation": "extract_continue",
                            "log_date": log_date
                        })
                    })

            if len(sqs_pages) > 0:
                return sqs.send_message_batch(
                    QueueUrl=queue_url,
                    Entries=sqs_pages
                )

            return "Nothing to continue"

    else:
        return "Invalid event source, nothing to do here"

    params = {"since": log_date, "page[number]": page}
    response = requests.get(url, headers=request_headers, params=params)
    data = response.json()
    audit_data = data["data"]

    if len(audit_data) > 0:

        print("Dumping", audit_data)

        # <log date>:<extract date/time>:<page number>
        file_name = (
            log_date + ":" +
            created.strftime("%Y%m%d-%H%M%S") + ":" +
            str(page) + ".json.gz"
        )
        file_path = "/tmp/" + file_name
        compress_json.dump(audit_data, file_path)

        s3 = boto3.resource("s3")
        s3.meta.client.upload_file(
            file_path,
            bucket,
            log_file_prefix + created.strftime("%Y%m%d") + "/" + file_name
        )

        return "File stored"

    return "Nothing to store"
