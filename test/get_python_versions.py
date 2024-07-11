import argparse
import json
import re
import urllib.request
from packaging import version

VERSIONS_URL = 'https://cdn.posit.co/python/versions.json'

# Minimum Python version for "all"
MIN_ALL_VERSION = version.parse('3.8.0')


def main():
    parser = argparse.ArgumentParser(description="Print python-builds python versions as JSON.")
    parser.add_argument(
        'versions',
        type=str,
        nargs='?',
        default='all',
        help="""Comma-separated list of versions. Specify "last-N" to use the
            last N minor python versions, or "all" to use all minor Python versions since 3.8.
            Defaults to "last-5".
            """
    )
    args = parser.parse_args()
    versions = _get_versions(which=args.versions)
    print(json.dumps(versions))


def _get_versions(which='all'):
    supported_versions = sorted(_get_supported_versions(), key=version.parse, reverse=True)
    versions = []
    for version_str in which.split(','):
        versions.extend(_expand_version(version_str, supported_versions))
    return versions

def _expand_version(which, supported_versions):
    last_n_versions = None
    if which.startswith('last-'):
        last_n_versions = int(which.replace('last-', ''))
    elif which != 'all':
        return [which] if which in supported_versions else []

    versions = {}
    for ver in supported_versions:
        parsed_ver = version.parse(ver)
        # Skip unreleased versions (e.g., devel, next)
        if not re.match(r'[\d.]', ver):
            continue
        if parsed_ver < MIN_ALL_VERSION:
            continue
        minor_ver = (parsed_ver.major, parsed_ver.minor)
        if minor_ver not in versions:
            versions[minor_ver] = ver
    versions = sorted(versions.values(), key=version.parse, reverse=True)

    if last_n_versions:
        return versions[0:last_n_versions]

    return versions


def _get_supported_versions():
    request = urllib.request.Request(VERSIONS_URL)
    response = urllib.request.urlopen(request)
    data = response.read()
    result = json.loads(data)
    return result['python_versions']


if __name__ == '__main__':
    main()
