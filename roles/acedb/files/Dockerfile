# aceDB Dockerfile

FROM ubuntu:14.04

## Install general packages
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget tree&& \
  rm -rf /var/lib/apt/lists/*

##Installing acedb
RUN apt-get update && \
    apt-get install -y libgtk2.0-0 libgtk2.0-dev libglib2.0-dev byacc csh \
     sharutils \
     gcc g++ \
     curl wget \
     bzip2 \
     mysql-client \
     mysql-server \
     libgd2-xpm-dev\
     xinetd \
     libdbd-mysql \
     libdbd-mysql-perl \
     libapache2-mod-perl2 \
     libgtk2.0 \
     libgtk2.0-dev \
     emacs \
     git \
     byacc \
     libreadline-gplv2-dev \
     flex \
     libdb4.6 \
     libdb-dev \
     xml2 libxml2 libxml2-dev \
     libmysql++-dev \
     ncurses-bin \
     libxmu-dev \
     graphviz \
     libssl-dev \
     uuid \
     uuid-dev \
     libxslt1-dev \
     xsltproc \
     libgdbm3 \
     ncurses-dev

# Set environment variables.
ENV HOME /root

#Adding user
RUN groupadd acedb
RUN useradd -g acedb acedb

RUN mkdir -p /root/acedb;
WORKDIR /root/acedb

COPY acedb-4.9.52.tgz .
CMD chmod 777 acedb-4.9.52.tgz
RUN tar xzf acedb-4.9.52.tgz

ENV ACEDB_MACHINE LINUX_4

# Define working directory.
WORKDIR /root/acedb

#test ace
ENTRYPOINT ["./acedb-4.9.52/sgifaceserver"]
CMD ["./wormbase", "2005"]
