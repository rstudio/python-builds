# python-builds

This repository orchestrates tools to produce Python binaries. The binaries are available as a
community resource, **they are not professionally supported by RStudio**. 
The Python language is open source, please see the official documentation at https://www.python.org/.

These binaries are not a replacement to existing binary distributions for Python.
The binaries were built with the following considerations:
- They use a minimal set of [build and runtime dependencies](builder).
- They are designed to be used side-by-side, e.g., on RStudio Workbench.
- They give users a consistent option for accessing R across different Linux distributions.

Please open an issue to report a specific
bug, or ask questions on [RStudio Community](https://community.rstudio.com).

## Supported Platforms

Python binaries are built for the following Linux operating systems:
- Ubuntu 18.04, 20.04, 22.04
- CentOS 7
- Red Hat Enterprise Linux 7, 8
- openSUSE 15.3
## Quick Installation

To use our quick install script to install R, simply run the following
command. To use the quick installer, you must have root or sudo privileges,
and `curl` must be installed.

```sh
bash -c "$(curl -L https://rstd.io/python-install)"
```

## Manual Installation

### Specify Python version

Define the version of R that you want to install. Available versions
of R can be found here: https://cdn.rstudio.com/python/versions.json
```bash
PYTHON_VERSION=3.5.3
```

### Download and install Python
#### Ubuntu/Debian Linux

Download the deb package:
```bash
# Ubuntu 18.04
wget https://cdn.rstudio.com/python/ubuntu-1804/pkgs/python-${PYTHON_VERSION}_1_amd64.deb

# Ubuntu 20.04
wget https://cdn.rstudio.com/python/ubuntu-2004/pkgs/python-${PYTHON_VERSION}_1_amd64.deb

# Ubuntu 22.04
wget https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb
```

Then install the package:
```bash
sudo apt-get install gdebi-core
sudo gdebi python-${PYTHON_VERSION}_1_amd64.deb
```

#### RHEL/CentOS Linux

Enable the [Extra Packages for Enterprise Linux](https://fedoraproject.org/wiki/EPEL)
repository (RHEL/CentOS 7 only):

```bash
# CentOS / RHEL 7
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```

> Note that on RHEL 7, you may also need to enable the Optional repository:
> ```bash
> # For RHEL 7 users with certificate subscriptions:
> sudo subscription-manager repos --enable "rhel-*-optional-rpms"
>
> # Or alternatively, using yum:
> sudo yum install yum-utils
> sudo yum-config-manager --enable "rhel-*-optional-rpms"
> ```

Download the rpm package:
```bash
# CentOS / RHEL 7
wget https://cdn.rstudio.com/python/centos-7/pkgs/python-${PYTHON_VERSION}-1-1.x86_64.rpm

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
wget https://cdn.rstudio.com/r/opensuse-153/pkgs/R-${R_VERSION}-1-1.x86_64.rpm
```

Then install the package:
```bash
sudo zypper --no-gpg-checks install R-${R_VERSION}-1-1.x86_64.rpm
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