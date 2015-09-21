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

#Adding user
RUN groupadd acedb
RUN useradd -g acedb -d /usr/local/wormbase/acedb acedb

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /data


#Adding directories
RUN cd /usr/local; \
    sudo mkdir wormbase; \
    sudo chown root:wormbase wormbase; \
    sudo chmod 2775 wormbase

RUN mkdir -p /root/acedb;


RUN mkdir -p /root/acedb/wormbase;
RUN mkdir -p /root/acedb/wormbase/database;
RUN mkdir -p /root/acedb/wormbase/wspec;

RUN touch /root/acedb/wormbase/wspec/models.wrm


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

#     libstdc++ 

#     libstdc++-devel  

#     libgd2-xpm \
#     libgdbm3-dev \


COPY ACEDB-source.4.9.39.tar.gz /root/acedb/ACEDB-source.4.9.39.tar.gz

CMD chmod 777 /root/acedb/ACEDB-source.4.9.39.tar.gz

ENV ACEDB_MACHINE LINUX_4

RUN cd /root/acedb; \
    tar xzf ACEDB-source*

RUN cd /root/acedb/w3rdparty; ./include-config glib-2.0 gtk2.0;

RUN cd /root/acedb; \
    make xace; \
    make tace; \ 
    make saceserver; \
    make sgifaceserver; \
    make saceclient


RUN cd ~/acedb; \
    ln -s bin.LINUX_4 bin; \
    sudo chown root:root ~/acedb/bin/*

#test ace
run  ~/acedb/bin/sgifaceserver ~/acedb/wormbase; sdfs

#    ln -s bin- \
#    cd 


# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
