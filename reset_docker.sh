#!/bin/bash

docker kill arangodb-instance ; docker rm arangodb-instance
docker run -e ARANGO_RANDOM_ROOT_PASSWORD=1 -p 8529:8529 --name arangodb-instance -d arangodb
newpw=$(docker logs arangodb-instance | head -n2 | grep PASSWORD | awk '{print $4}')
echo $newpw | pbcopy
sed -i.bak "s/export ARANGO_PASSWORD=.*/export ARANGO_PASSWORD=$newpw/" ../.envrc
cat ../.envrc
direnv allow 
echo "New password has been copied to the clipboard."
