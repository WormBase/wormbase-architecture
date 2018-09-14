docker stop acedb;
docker rm acedb;
docker run -d --name acedb --restart unless-stopped --net wb-network -v /usr/local/wormbase/acedb/wormbase:/root/acedb/wormbase/ --publish 2005:2005 -t wormbase/acedb
