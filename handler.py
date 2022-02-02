from bs4 import BeautifulSoup
import boto3
import botocore
import json
import os
import requests

PYTHON_SRC_URL = 'https://www.python.org/ftp/python/'
PYTHON_MINOR_VERSIONS = ['3.7', '3.8', '3.9', '3.10']
batch_client = boto3.client('batch', region_name='us-east-1')


def _to_list(input):
    """Normalize a list (list or string) to list."""
    if isinstance(input, list):
        return input
    return input.split(',')


def _persist_python_versions(data):
    """Ship current list to s3."""
    s3 = boto3.resource('s3')
    obj = s3.Object(os.environ['S3_BUCKET'], 'python/versions.json')
    obj.put(Body=json.dumps(data), ContentType='application/json')


def _valid_python_version(version):
    """Determine if this is a valid python version from PYTHON_MINOR_VERSIONS"""
    for minor_version in PYTHON_MINOR_VERSIONS:
        if version.startswith(minor_version):
            return True
    return False


def _python_versions():
    """Perform a lookup of python.com known versions."""
    r = requests.get(PYTHON_SRC_URL)
    soup = BeautifulSoup(r.text, 'html.parser')
    python_versions = []
    for link in soup.find_all('a'):
        href = link.get('href').replace('/', '')
        if _valid_python_version(href):
            python_versions.append(href)
    return {'python_versions': python_versions}


def _known_python_versions():
    """Get current list from s3."""
    try:
        s3 = boto3.resource('s3')
        obj = s3.Object(os.environ['S3_BUCKET'], 'python/versions.json')
        str = obj.get()['Body'].read().decode('utf-8')
    except botocore.exceptions.ClientError:
        print('Key not found, using empty list')
        str = '{"python_versions":[]}'
    return json.loads(str)


def _compare_versions(fresh, known):
    """Compare fresh python list to new list and return unknown versions."""
    new = set(fresh) - set(known)
    return list(new)


def _versions_to_build(force, versions):
    python_versions = _python_versions()['python_versions']
    if versions:
        python_versions = [v for v in python_versions if v in versions]
    known_versions = _known_python_versions()['python_versions']
    new_versions = _compare_versions(python_versions, known_versions)

    if len(new_versions) > 0:
        print('New Python Versions found: %s' % new_versions)
        _persist_python_versions(_python_versions())

    if force in [True, 'True', 'true']:
        return python_versions
    else:
        return new_versions


def _container_overrides(version):
    """Generate container override parameter for jobs."""
    overrides = {}
    overrides['environment'] = [
        {'name': 'PYTHON_VERSION', 'value': version},
        {'name': 'S3_BUCKET', 'value': os.environ['S3_BUCKET']}
    ]
    return overrides


def _submit_job(version, platform):
    """Submit a Python build job to AWS Batch."""
    job_name = '-'.join(['python', version, platform])
    job_name = job_name.replace('.', '_')
    job_definition_arn = 'JOB_DEFINITION_ARN_{}'.format(platform.replace('-', '_'))
    args = {
        'jobName': job_name,
        'jobQueue': os.environ['JOB_QUEUE_ARN'],
        'jobDefinition': os.environ[job_definition_arn],
        'containerOverrides': _container_overrides(version)
    }
    if os.environ.get('DRYRUN'):
        print('DRYRUN: would have queued {}'.format(job_name))
        return 'dryrun-no-job-{}'.format(job_name)
    else:
        response = batch_client.submit_job(**args)
        print("Started job for Python:{},Platform:{},id:{}".format(version, platform, response['jobId']))
        return response['jobId']


def _check_for_job_status(jobs, status):
    """Return a subset of job ids which match a given status."""
    r = batch_client.list_jobs(jobQueue=os.environ['JOB_QUEUE_ARN'], jobStatus=status)
    return [i['jobId'] for i in r['jobSummaryList'] if i['jobId'] in jobs]


def queue_builds(event, context):
    """Queue some builds."""
    event['versions_to_build'] =  _versions_to_build(event.get('force', False), event.get('versions'))
    event['supported_platforms'] = _to_list(os.environ.get('SUPPORTED_PLATFORMS', 'ubuntu-2004'))
    job_ids = []
    for version in event['versions_to_build']:
        for platform in event['supported_platforms']:
            job_ids.append(_submit_job(version, platform))
    event['jobIds'] = job_ids
    return event


def poll_running_jobs(event, context):
    """Query job queue for current queue depth."""
    event['failedJobIds'] = _check_for_job_status(event['jobIds'], 'FAILED')
    event['succeededJobIds'] = _check_for_job_status(event['jobIds'], 'SUCCEEDED')
    event['failedJobCount'] = len(event['failedJobIds'])
    event['finishedJobCount'] = len(event['failedJobIds']) + len(event['succeededJobIds'])
    event['unfinishedJobCount'] = len(event['jobIds']) - event['finishedJobCount']
    return event
