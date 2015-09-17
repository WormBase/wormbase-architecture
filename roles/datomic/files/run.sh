#!/bin/bash
set -e

ip=ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
sed "s/alt-host=127.0.0.1/alt-host=$ip/" -i ~/datomic/free-transactor.properties

/root/datomic/bin/transactor /root/datomic/free-transactor.properties
