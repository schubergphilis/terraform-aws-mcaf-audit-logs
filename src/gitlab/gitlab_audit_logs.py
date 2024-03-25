import boto3
import compress_json
import datetime
import logging
import os
import requests

logger = logging.getLogger()
logger.setLevel(logging.os.environ["log_level"].upper())

def fetch_token(token_secret_name):
    secrets_client = boto3.client("secretsmanager")
    secret_response = secrets_client.get_secret_value(
        SecretId=token_secret_name
    )

    return secret_response["SecretString"]


def get_group_ids(initial_url, headers):
    url = f'{initial_url}/groups'
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        groups = response.json()
        group_ids = [group['id'] for group in groups]
        return group_ids
    else:
        logging.error(f'Error getting group IDs: {response.status_code}')
        return []


def get_project_ids(initial_url, headers, group_id, project_ids):
    url = f'{initial_url}/groups/{group_id}/projects'
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        projects = response.json()
        list_of_group_project_ids = [project['id'] for project in projects]
        project_ids.update(list_of_group_project_ids)
        return project_ids
    else:
        logging.error(f'Error getting project IDs: {response.status_code}')
        return []


def get_audit_events(url, headers, data, id, type="group"):
    complete_url = f'{url}/{type}/{id}/audit_events'
    response = requests.get(
        complete_url,
        headers=headers,
        data=data
    )
    if response.status_code == 200:
        return response.json()
    else:
        logging.error(f'Error getting audit events for {type} {id}: {response.status_code}')
        return []


def upload_to_s3(file_name, bucket, audit_data, type="groups"):
    file_path = "/tmp/" + file_name
    compress_json.dump(audit_data, file_path)
    s3 = boto3.resource("s3")
    file = f'gitlab_{type}_audit_log/{file_name}'
    logging.info(f'Dumping Gitlab {type} audit data')
    s3.meta.client.upload_file(
        file_path,
        bucket,
        file
    )


# Main function to get and print audit events for all groups and projects
def handler(event, context):
    project_ids = set()
    all_group_audit_events = []
    all_project_audit_events = []
    token_secret_name = os.environ["token_secret_name"]
    token = fetch_token(token_secret_name)
    bucket = os.environ["logs_bucket"]
    initial_url = os.environ["logs_url"]

    headers = {
        'PRIVATE-TOKEN': token
    }
    today = datetime.date.today()
    created = today - datetime.timedelta(days=int(os.environ["days_of_audit_logs"]))
    created_after = created.strftime("%Y-%m-%dT%H:%M:%SZ")
    created_before = today.strftime("%Y-%m-%dT%H:%M:%SZ")
    data = {
        "created_after": created_after,
        "created_before": created_before
    }
    logging.info(f'Logging that will be collected will be between {created_after} and {created_before}')
    group_ids = get_group_ids(initial_url, headers)
    logging.debug(f'List of group ids {group_ids}')

    for group_id in group_ids:
        group_audit_events = get_audit_events(
            url=initial_url,
            headers=headers,
            data=data,
            id=group_id,
            type="groups"
        )
        logging.debug(f'Audit events for group {group_id}: {group_audit_events}')
        all_group_audit_events += group_audit_events
        project_ids = get_project_ids(
            initial_url,
            headers,
            group_id,
            project_ids
        )
    logging.debug(f'List of project ids {project_ids}')

    for project_id in project_ids:
        project_audit_events = get_audit_events(
            url=initial_url,
            headers=headers,
            data=data,
            id=project_id,
            type="projects"
        )
        logging.debug(f'Audit events for project {project_id}: {project_audit_events}')
        all_project_audit_events += project_audit_events

    file_name = (
        created.strftime("%Y%m%d") + ".json.gz"
    )

    upload_to_s3(
        file_name=file_name,
        bucket=bucket,
        audit_data=all_group_audit_events,
        type="groups"
    )

    upload_to_s3(
        file_name=file_name,
        bucket=bucket,
        audit_data=all_project_audit_events,
        type="projects"
    )

    return "File stored"
