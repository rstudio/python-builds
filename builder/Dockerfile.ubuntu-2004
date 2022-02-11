FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV OS_IDENTIFIER=ubuntu-2004

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
  wget \
  ;

RUN apt-get install -y \
  gcc \
  libbz2-dev \
  libffi-dev \
  libgdbm-dev \
  liblzma-dev \
  libncurses-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  make \
  tk-dev \
  zlib1g-dev \
  ruby \ 
  ruby-dev \
  ;

RUN gem install fpm

COPY build.sh /build.sh

ENTRYPOINT ["/build.sh"]
CMD []
