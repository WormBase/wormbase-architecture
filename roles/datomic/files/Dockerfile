FROM ubuntu:14.04

MAINTAINER Adam Wright "adamwright@wormbase.org"

ENV DATOMIC_VERSION 0.9.5206
ENV DATOMIC_HOME /root/datomic/datomic
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $JAVA_HOME:/bin:/usr/bin:$PATH $JAVA_HOME:/bin:/usr/bin:$PATH

## update packages
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y unzip wget && \
  apt-get install -y openjdk-7-jdk && \
  apt-get install -y vim && \
  rm -rf /var/lib/apt/lists/*

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["bash"]

# Setup Datomic

## move datomic into container
ADD ./datomic-free-0.9.5206.zip /tmp/datomic-free-0.9.5206.zip

## make datomic directories
RUN mkdir ~/temp
RUN mkdir ~/datomic
RUN mkdir ~/datomic_data
RUN mkdir ~/datomic_configs

## Make sure to have a config/ folder in the same folder as your
# Dockerfile containing the transactor property file you wish to use
RUN unzip /tmp/datomic-free-0.9.5206.zip -d ~/temp

RUN cp -r ~/temp/datomic-free-0.9.5206/* ~/datomic
RUN rm -r ~/temp

#-- IMPORT transactor file from vagrant HOST into container
ADD configs/free-transactor.properties /root/datomic_configs/free-transactor.properties

#-- RUN DATOMIC
# copy default transactor into datomic root
RUN cp ~/datomic/config/samples/free-transactor-template.properties ~/datomic/free-transactor.properties

# modify url in transactor file
RUN sed "s/host=localhost/host=0.0.0.0/" -i ~/datomic/free-transactor.properties
RUN sed "/host=0.0.0.0/a alt-host=private-ip/" -i ~/datomic/free-transactor.properties

# -- execute free transactor with updated settings
CMD ["/root/datomic/bin/transactor", "/root/datomic/free-transactor.properties"]

EXPOSE 4334
