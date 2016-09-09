FROM ubuntu:14.04

MAINTAINER Adam Wright "adamwright@wormbase.org"

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $JAVA_HOME:/bin:/usr/bin:$PATH $JAVA_HOME:/bin:/usr/bin:$PATH

## Lein environment variables

# Port to bind (default 8210)
#ENV  TRACE_PORT

#Port on which to run an HTTPS service (optional)
#ENV TRACE_SSL_PORT

#Path of a .jks file containing certificates
#ENV TRACE_SSL_KEYSTORE

#Password to use when accessing the keystore
#ENV TRACE_SSL_PASSWORD       

#From OAuth provider (if using federated login)
#ENV TRACE_OAUTH2_CLIENT_ID

#From OAuth provider (if using federated login)
#ENV TRACE_OAUTH2_CLIENT_SECRET

#Public URL that the server is running on
#ENV TRACE_OAUTH2_REDIRECT_DOMAIN

#URI of a Datomic database
#ENV TRACE_DB datomic:free://172.17.0.126:4334/WS250

#Require authentication for all pages
#ENV TRACE_REQUIRE_LOGIN          


#Provide an /api/query end-point compatible with the standard Datomic REST adapter
#ENV TRACE_ACCEPT_REST_QUERY      

#Enable "name-server" style curation forms
#ENV TRANCE_ENABLE_CURATION_FORMS



## update packages
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y unzip wget git && \
  apt-get install -y openjdk-7-jdk && \
  apt-get install -y vim && \ 
  rm -rf /var/lib/apt/lists/*

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]

COPY acedb-WS25-2015-09-04.tar.gz /root/acedb-WS25-2015-09-04.tar.gz


#setup lein
ENV LEIN_ROOT true

RUN wget -q -O /usr/bin/lein \
    https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein \
    && chmod +x /usr/bin/lein

RUN lein

RUN git clone https://github.com/WormBase/db.git

#installing development web services

##get dependencies
RUN cd db/pseudoace \
    lein deps \
    lein cljsbuild once 

EXPOSE 3210
