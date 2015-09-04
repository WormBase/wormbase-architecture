[![Build Status](https://travis-ci.org/a8wright/wormbase-architecture.svg?branch=develop)](https://travis-ci.org/a8wright/wormbase-architecture) 

# wormbase-architecture
This repository is a set of code that can be used to setup the varios WormBase environments

The main provisioning tool that is used in the repostitory is Ansible.

##Getting started - install Ansible

First you will need to install docker and other dependencies on your host machine

###Command
	ansible-playbook -i inventory install.yml

###Result
	If you see the line "Complete!" at the end of the output everyting has been installed correctly

Once you have gone through the initial installation you will be ready to start spinning up docker containers. 

###Command 
	ansible-playbook -i inventory site.yml

###Result 
	When you run "sudo docker images" you should now see the image "wormbase-datomic" listed as a docker image

##In order to shell into the datomic container run the following command

	sudo docker run -it wormbase-datomic /bin/bash

##Although the playbook will already get the docker container runnig

	sudo docker exec -it wombase-datatomic /bin/bash

##To figure see the running docker container

	sudo docker ps

##To figure out the docker containers ip address

	sudo  docker inspect  (look for NetworkSettings -> IPAddress )

##To connect to machine and inspect the container with bash 

	sudo docker exec -it <container-id | container-name> bash

	


