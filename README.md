# python-builds

This repository orchestrates tools to produce Python binaries. 
The Python language is open source, please see the official documentation at https://www.python.org/.

These binaries are not a replacement to existing binary distributions for Python.
The binaries were built with the following considerations:
- They use a minimal set of [build and runtime dependencies](builder).
- They are designed to be used side-by-side, e.g., on RStudio Workbench.
- They give users a consistent option for accessing Python across different Linux distributions.

Please open an issue to report a specific
bug, or ask questions on [RStudio Community](https://community.rstudio.com).

## Supported Platforms

Python binaries are built for the following Linux operating systems:
- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- Red Hat Enterprise Linux 8, 9
- openSUSE 15.5

## Quick Installation

To use our quick install script to install Python, simply run the following
command. To use the quick installer, you must have root or sudo privileges,
and `curl` must be installed.

```sh
bash -c "$(curl -L https://rstd.io/python-install)"
```

## Manual Installation

### Specify Python version

Define the version of Python that you want to install. Available versions
of Python can be found here: https://cdn.rstudio.com/python/versions.json
```bash
PYTHON_VERSION=3.11.9
```

### Download and install Python
#### Ubuntu/Debian Linux

Download the deb package:
```bash
# Ubuntu 20.04
wget https://cdn.rstudio.com/python/ubuntu-2004/pkgs/python-${PYTHON_VERSION}_1_amd64.deb

# Ubuntu 22.04
wget https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb

# Ubuntu 24.04
wget https://cdn.rstudio.com/python/ubuntu-2404/pkgs/python-${PYTHON_VERSION}_1_amd64.deb
```

Then install the package:
```bash
sudo apt-get install gdebi-core
sudo gdebi python-${PYTHON_VERSION}_1_amd64.deb
```

#### RHEL/CentOS Linux

> # using yum:
> sudo yum install yum-utils
> sudo yum-config-manager --enable "rhel-*-optional-rpms"
> ```

Download the rpm package:
```bash
# RHEL 8
wget https://cdn.rstudio.com/python/centos-8/pkgs/python-${PYTHON_VERSION}-1-1.x86_64.rpm
```

Then install the package:
```bash
sudo yum install python-${PYTHON_VERSION}-1-1.x86_64.rpm
```

#### SUSE Linux

Enable the Python backports repository (SLES 12 only):
```bash
# SLES 12
VERSION="SLE_$(grep "^VERSION=" /etc/os-release | sed -e 's/VERSION=//' -e 's/"//g' -e 's/-/_/')"
sudo zypper --gpg-auto-import-keys addrepo https://download.opensuse.org/repositories/devel:/languages:/python:/backports/$VERSION/devel:languages:python:backports.repo
```

Download the rpm package:
```bash
# openSUSE 15.3 / SLES 15 SP3
wget https://cdn.rstudio.com/python/opensuse-153/pkgs/python-${PYTHON_VERSION}-1-1.x86_64.rpm
```

Then install the package:
```bash
sudo zypper --no-gpg-checks install python-${PYTHON_VERSION}-1-1.x86_64.rpm
```

### Verify Python installation

Test that Python was successfully installed by running:
```bash
/opt/python/${PYTHON_VERSION}/bin/python --version
```

### Add Python to the system path

To ensure that Python is available on the system path, create symbolic links to
the version of Python that you installed:

```bash
sudo ln -s /opt/python/${PYTHON_VERSION}/bin/python /usr/local/bin/python 
```

### Optional post-installation steps

If you want to install multiple versions of Python on the same system, you can
repeat these steps to install a different version of Python alongside existing versions.

---

# Developer Documentation

This repository orchestrates builds using a variety of tools. The
instructions below outline the components in the stack and describe how to add a
new platform or inspect an existing platform.

## Adding a new platform:

### Dockerfile

Create a `builder/Dockerfile.platform-version` (where `platform-version` is `ubuntu-2204` or `centos-7`, etc.) This file must contain four major tasks:

1. an `OS_IDENTIFIER` env with the `platform-version`.
2. a step which ensures the Python source build dependencies are installed
3. The `awscli`, 1.17.10+ if installed via `pip`, for uploading tarballs to S3
4. `COPY` and `ENTRYPOINT` for the `build.sh` file in `builder/`.

### docker-compose.yml

A new service in the docker-compose file named according to the `platform-version` and containing the proper entries:

```
command: ./build.sh
environment:
  - PYTHON_VERSION=${PYTHON_VERSION} # for testing out Python builds locally
  - LOCAL_STORE=/tmp/output # ensures that output tarballs are persisted locally
build:
  context: .
  dockerfile: Dockerfile.debian-12
image: python-builds:debian-12
volumes:
  - ./integration/tmp:/tmp/output  # path to output tarballs
```

### Job definition

IN `serverless-resources.yml` you'll need to add a job definition that points to the ECR image.

```
pythonBuildsBatchJobDefinitionDebian12:
  Type: AWS::Batch::JobDefinition
  Properties:
    Type: container
    ContainerProperties:
      Command:
        - ./build.sh
      Vcpus: 4
      Memory: 4096
      JobRoleArn:
        "Fn::GetAtt": [ pythonBuildsEcsTaskIamRole, Arn ]
      Image: #{AWS::AccountId}.dkr.ecr.#{AWS::Region}.amazonaws.com/python-builds:debian-12
```

### Environment variables in the serverless.yml functions.

The serverless functions which trigger Python builds need to be informed of new platforms.

1. Add a `JOB_DEFINITION_ARN_PlatformVersion` env variable with a ref to the Job definition above.
2. Append the `platform-version` to `SUPPORTED_PLATFORMS`.

```
environment:
  # snip
  JOB_DEFINITION_ARN_debian_12:
    Ref: pythonBuildsBatchJobDefinitionDebian12
  SUPPORTED_PLATFORMS: centos-7,centos-8,debian-12
```

### Makefile

In order for the makefile to push these new platforms to ECR, add them to the PLATFORMS variable near the top of the Makefile

### Submit a Pull Request

Once you've followed the steps above, submit a pull request. On successful merge, builds for this platform will begin to be available from the CDN.

## "Break Glass"

Periodically, someone with access to these resources may need to re-trigger every Python version/platform combination. This quite easy with the `serverless` tool installed.

```bash
# Rebuild all Python versions
serverless invoke stepf -n pythonBuilds -d '{"force": true}'

# Rebuild specific Python versions
serverless invoke stepf -n pythonBuilds -d '{"force": true, "versions": ["3.10.1", "3.11.9"]}'
```

## Testing

To test the Python builds locally, you can build the images:

```bash
# Build images for all platforms
make docker-build

# Or build the image for a single platform
(cd builder && docker compose build ubuntu-2404)
```

Then run the build script:

```bash
# Build Python for all platforms
PYTHON_VERSION=3.11.9 make docker-build-python

# Build pre-release version for all platforms
PYTHON_VERSION=3.13.0rc3 make docker-build-python

# Build Python for a single platform
(cd builder && PYTHON_VERSION=3.11.9 docker compose up ubuntu-2404)

# Alternatively, run the build script from within a container
docker run -it --rm --entrypoint "/bin/bash" python-builds:ubuntu-2404

# Build Python 3.11.9
PYTHON_VERSION=3.11.9 ./build.sh
```
