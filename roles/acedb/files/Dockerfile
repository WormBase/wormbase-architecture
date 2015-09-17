# aceDB Dockerfile

FROM ubuntu:14.04

## Install general packages
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  rm -rf /var/lib/apt/lists/*

#Adding user
RUN groupadd acedb
RUN useradd -g acedb -d /usr/local/wormbase/acedb acedb

#Adding directories
RUN cd /usr/local; \
    sudo mkdir wormbase; \
    sudo chown root:wormbase wormbase; \
    sudo chmod 2775 wormbase

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
