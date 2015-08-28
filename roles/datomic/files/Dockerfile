FROM pointslope/clojure:lein-2.5.0

MAINTAINER Adam Wright "adamwright@wormbase.org"

ENV DATOMIC_VERSION 0.9.5130
ENV DATOMIC_HOME /opt/datomic-pro-$DATOMIC_VERSION

# Datomic Pro Starter as easy as 1-2-3
# 1. Create a .credentials file containing user:pass
# for downloading from my.datomic.com
ONBUILD ADD .credentials /tmp/.credentials

# 2. Make sure to have a config/ folder in the same folder as your
# Dockerfile containing the transactor property file you wish to use
ONBUILD RUN curl datomic-free-0.9.5206.zip\
  && unzip /tmp/datomic.zip -d /opt \
  && rm -f /tmp/datomic.zip

WORKDIR $DATOMIC_HOME

# 3. Provide a CMD with an alias to the database
# and the database uri
# e.g. CMD ["dev", "datomic:dev://db:4334/"]
ENTRYPOINT ["bin/console", "-p", "9000"]

EXPOSE 9000


