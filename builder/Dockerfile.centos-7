FROM centos:centos7

ENV OS_IDENTIFIER=centos-7

# RUN sed -i 's/^enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo && yum -y update

RUN yum -y install \
  autoconf \
  bluez-libs-devel \
  bzip2 \
  bzip2-devel \
  expat-devel \
  gcc-c++ \
  gdbm-devel \
  git \
  glibc-devel \
  gmp-devel \
  libX11-devel \
  libdb-devel \
  libffi-devel \
  mesa-libGL-devel \
  ncurses-devel \
  openssl-devel \
  readline-devel \
  sqlite-devel \
  systemtap-sdt-devel \
  tcl-devel \
  tix-devel \
  tk-devel \
  valgrind-devel \
  zlib-devel \
  rpm-build \
  readline-devel \
  make \
  ruby \ 
  ruby-devel \
  && yum clean all

# Pin fpm for compatibility with Ruby < 2.3
RUN gem install ffi:1.12.2 fpm:1.11.0

COPY build.sh /build.sh

ENTRYPOINT ["/build.sh"]
CMD []

