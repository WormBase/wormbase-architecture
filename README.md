[![Build Status](https://travis-ci.org/a8wright/wormbase-architecture.svg?branch=develop)](https://travis-ci.org/a8wright/wormbase-architecture) 

# wormbase-architecture
This repository is a set of code that can be used to setup the varios WormBase environments

The main provisioning tool that is used in the repostitory is Ansible.

##Getting started - install Ansible

First you will need to install docker and other dependencies on your host machine

### mount devices
        Follow instruction from http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html
        eg. sudo mkfs -t xfs /dev/xvdf; sudo mount /dev/xvdf /datastore;

### start datomic transactor
	sudo ~/datomic/bin/transactor ~/datomic_configs/free-transactor.properties

###Command 1
	ansible-playbook -i inventory install.yml

###Command 2
	ansible-playbook -i inventory site.yml

###Result 
	When you run "sudo docker images" you should now see the image "wormbase-datomic" listed as a docker image


##Loading data into acedb
        foreach acefile (`ls /datastore/acedb/raw-data/WS250/*.ace`)
            tace <<quit
                parse $acefile
            quit
        end


## Using Containers

###General

####To figure see the running docker container

	sudo docker ps

####To figure out the docker containers ip address

	sudo  docker inspect  (look for NetworkSettings -> IPAddress )

####To connect to machine and inspect the container with bash 

	sudo docker exec -it <container-id | container-name> bash

	

###Database (posgresql)

This database could be used in stead of the free storage protocol with Datomic

Data is stored in /var/log/postresql/data.

####Log in from remote host

     psql -U postgres -h <postgres-container-ip-addr>  

####Start Container

     ansible-playbook -i inventory postgresql.yml;

###Datomic

Datomic will already be running you will be able to connect with it either through port 4334 or through ssh

####To shell into the container

	sudo docker exec -it wombase-datatomic /bin/bash

###Datomic API

        sudo docker run -d -P --name wormbase-datomic-api --link wormbase-datomic:wormbase-datomic wormbase-datomic-api /bin/bash


##Running lein

I am following the docker links to make a connection to the datomic database. To do the host needs to be modified to 

	(def uri "datomic:free://WORMBASE_DATOMIC_PORT_4224_TCP/wb250-imp1

In the script on the following page:

	https://github.com/WormBase/db/wiki/Timestamp-Importer
