#!/bin/bash
set -e

export S3_BUCKET_PREFIX=${S3_BUCKET_PREFIX-""}
export OS_IDENTIFIER=${OS_IDENTIFIER-"unknown"}
export TARBALL_NAME="python-${PYTHON_VERSION}-${OS_IDENTIFIER}.tar.gz"

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
    echo "Storing artifact on s3: ${S3_BUCKET}, tarball: ${TARBALL_NAME}"
    aws s3 cp /tmp/${TARBALL_NAME} s3://${S3_BUCKET}/${S3_BUCKET_PREFIX}${baseName}/${TARBALL_NAME}
    # check if PKG_FILE has been set by a packager script and act accordingly
    if [ -n "$PKG_FILE" ] && [ "$PKG_FILE" != "" ]; then
      if [ -f "$PKG_FILE" ]; then
	aws s3 cp ${PKG_FILE} s3://${S3_BUCKET}/${S3_BUCKET_PREFIX}${baseName}/pkgs/$(basename ${PKG_FILE})
      fi
    fi
  fi
  if [ -n "$LOCAL_STORE" ] && [ "$LOCAL_STORE" != '' ]; then
    echo "Storing artifact locally: ${LOCAL_STORE}, tarball: ${TARBALL_NAME}"
    mkdir -p ${LOCAL_STORE}/${baseName}
    cp /tmp/${TARBALL_NAME} ${LOCAL_STORE}/${baseName}/${TARBALL_NAME}
  fi
}

# archive_python() - $1 as python version
archive_python() {
  tar czf /tmp/${TARBALL_NAME} --directory=/opt/python ${1} --owner=0 --group=0
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
  ./configure \
    --prefix=/opt/python/${VERSION} \
    --enable-shared \
    --enable-ipv6 \
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

set_up_environment() {
  mkdir -p /opt/python
}

###### RUN PYTHON COMPILE PROCEDURE ######
set_up_environment
fetch_python_source $PYTHON_VERSION
compile_python $PYTHON_VERSION
package_python $PYTHON_VERSION
archive_python $PYTHON_VERSION
upload_python $PYTHON_VERSION
