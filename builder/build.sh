#!/bin/bash
set -ex

export S3_BUCKET_PREFIX=${S3_BUCKET_PREFIX-""}
export OS_IDENTIFIER=${OS_IDENTIFIER-"unknown"}
export TARBALL_NAME="python-${PYTHON_VERSION}-${OS_IDENTIFIER}.tar.gz"
export JUPYTER_TARBALL_NAME="python-${PYTHON_VERSION}-jupyter-${OS_IDENTIFIER}.tar.gz"

# Some Dockerfiles may copy a `/env.sh` to set up environment variables
# that require command substitution. If this file exists, source it.
if [[ -f /env.sh ]]; then
    echo "Sourcing environment variables"
    source /env.sh
fi

# upload_python()
upload_python() {
  baseName="python/${OS_IDENTIFIER}"
  if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "" ]; then
    echo "Storing artifacts on s3: ${S3_BUCKET}, tarball: ${TARBALL_NAME}, jupyter: ${JUPYTER_TARBALL_NAME}"
    aws s3 cp /tmp/${TARBALL_NAME} s3://${S3_BUCKET}/${S3_BUCKET_PREFIX}${baseName}/${TARBALL_NAME}
    aws s3 cp /tmp/${JUPYTER_TARBALL_NAME} s3://${S3_BUCKET}/${S3_BUCKET_PREFIX}${baseName}/${JUPYTER_TARBALL_NAME}
    # check if PKG_FILE has been set by a packager script and act accordingly
    if [ -n "$PKG_FILE" ] && [ "$PKG_FILE" != "" ]; then
      if [ -f "$PKG_FILE" ]; then
	  aws s3 cp ${PKG_FILE} s3://${S3_BUCKET}/${S3_BUCKET_PREFIX}${baseName}/pkgs/$(basename ${PKG_FILE})
      fi
    fi
  fi
  if [ -n "$LOCAL_STORE" ] && [ "$LOCAL_STORE" != '' ]; then
    echo "Storing artifacts locally: ${LOCAL_STORE}, tarball: ${TARBALL_NAME}, jupyter: ${JUPYTER_TARBALL_NAME}"
    mkdir -p ${LOCAL_STORE}/${baseName}
    cp /tmp/${TARBALL_NAME} ${LOCAL_STORE}/${baseName}/${TARBALL_NAME}
    cp /tmp/${JUPYTER_TARBALL_NAME} ${LOCAL_STORE}/${baseName}/${JUPYTER_TARBALL_NAME}
  fi
}

# archive_python() - $1 as python version, $2 as target filename
archive_python() {
        ls -l /opt/python 
	tar czf /tmp/${2} --directory=/opt/python ${1} --owner=0 --group=0
}

# fetch_python_source() - $1 as python version
fetch_python_source() {
  echo "Downloading python-${1}"
  wget -q "https://www.python.org/ftp/python/${1}/Python-${1}.tgz" -O /tmp/python-${1}.tgz
  echo "Extracting python-${1}"
  tar xf /tmp/python-${1}.tgz -C /tmp
  rm /tmp/python-${1}.tgz
}

# compile_python() - $1 as python version
compile_python() {
  local VERSION=${1}
  local PYTHON_MAJOR=$(cut -d'.' -f1 <<<$1)

  cd /tmp/Python-${VERSION}

  build_flag="--build=$(uname -m)-pc-linux-gnu"

  ./configure \
    --prefix=/opt/python/${VERSION} \
    --enable-shared \
    --enable-optimizations \
    --enable-ipv6 \
    ${build_flag} \
    LDFLAGS=-Wl,-rpath=/opt/python/${VERSION}/lib,--disable-new-dtags

  make clean
  make
  make install
}

package_python() {
  if [[ -f /package.sh ]]; then
    export PYTHON_VERSION=${1}
    source /package.sh
  fi
}

install_ipykernel() {
  local VERSION=${1}
  local PYTHON_MAJOR=$(cut -d'.' -f1 <<<$1)

  wget -q https://bootstrap.pypa.io/get-pip.py
  /opt/python/${VERSION}/bin/python${PYTHON_MAJOR} get-pip.py
  /opt/python/${VERSION}/bin/pip install ipykernel
}

set_up_environment() {
  mkdir -p /opt/python
}

###### RUN PYTHON COMPILE PROCEDURE ######
set_up_environment
fetch_python_source "$PYTHON_VERSION"
compile_python "$PYTHON_VERSION"
archive_python "${PYTHON_VERSION}" "${TARBALL_NAME}"
package_python "$PYTHON_VERSION"
install_ipykernel "$PYTHON_VERSION"
archive_python "${PYTHON_VERSION}" "${JUPYTER_TARBALL_NAME}"
upload_python "$PYTHON_VERSION"
