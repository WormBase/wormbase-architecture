docker stop acedb;
docker rm acedb;
docker run -d --name acedb --restart unless-stopped --net wb-network -v /usr/local/wormbase/acedb/wormbase:/acedb/wormbase/ --publish 2005:2005 -t wormbase/acedb /root/acedb/acedb-4.9.52/sgifaceserver /acedb/wormbase 2005
