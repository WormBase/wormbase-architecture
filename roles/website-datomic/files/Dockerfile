# Wormbase Docker WebSite Dockerfile

FROM ubuntu:14.04
MAINTAINER Adam Wright <adam.wright@wormbase.org>

#Install general packages
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  rm -rf /var/lib/apt/lists/*

## Install library prerequisites
RUN sudo apt-get update; \
    sudo apt-get -y install \
      zlib1g-dev \
      uuid \
      uuid-dev 

#Adding user
RUN groupadd wormbase
RUN usermod -a -G wormbase root

#Adding directories not sure *** is this is needed for this image
RUN cd /usr/local; \
    sudo mkdir -p wormbase; \
    sudo chown root:wormbase wormbase; \
    sudo chmod 2775 wormbase

RUN mkdir -p /usr/local/wormbase/website; \
    chmod 2775 /usr/local/wormbase/website; \
    sudo chgrp wormbase /usr/local/wormbase/website

RUN mkdir -p /usr/local/wormbase/services; \
    chmod 2775 /usr/local/wormbase/services; \
    sudo chgrp wormbase /usr/local/wormbase/services

RUN mkdir -p /usr/local/wormbase/databases; \
    chmod 2775 /usr/local/wormbase/databases; \
    sudo chgrp wormbase /usr/local/wormbase/databases

RUN mkdir -p /usr/local/wormbase/logs; \
    chmod 2775 /usr/local/wormbase/logs; \
    sudo chgrp wormbase /usr/local/wormbase/logs

#install xapian
RUN wget http://oligarchy.co.uk/xapian/1.2.5/xapian-core-1.2.5.tar.gz; \
    tar -xvzf xapian-core-1.2.5.tar.gz; \
    mv xapian-core-1.2.5 xapian-core; \
    ls -l; \
    cd xapian-core; \
    ./configure; \
    make; \
    sudo make install

#install website
RUN cd  /usr/local/wormbase/website; \
    git clone https://github.com/dasmoth/website.git; \
    git checkout origin/json-client; \ 
    mv website develop

#install website dependencies
RUN sudo apt-get update; \
    sudo apt-get -y install \
      libmodule-install-perl \
      libclass-singleton-perl

RUN mkdir -p /usr/local/wormabase/extlib; \
    cd /usr/local/wormbase/website/develop; \
    perl Makefile.PL; \
    make installdeps; 

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
