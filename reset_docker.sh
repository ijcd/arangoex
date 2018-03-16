#!/bin/bash

docker kill arangodb-instance ; docker rm arangodb-instance
docker run --privileged -e ARANGO_RANDOM_ROOT_PASSWORD=1 -p 8529:8529 --name arangodb-instance -d arangodb:3.1.26 bash -c "echo 2 >/proc/sys/vm/overcommit_memory && arangod"
newpw=$(docker logs arangodb-instance | head -n10 | grep PASSWORD | awk '{print $4}')
echo $newpw | pbcopy
sed -i.bak "s/export ARANGO_PASSWORD=.*/export ARANGO_PASSWORD=$newpw/" ../.envrc
cat ../.envrc
direnv allow
echo "New password has been copied to the clipboard."
echo "Arango is running with admin at http://localhost:8529 (provided you are using Docker for Mac)"
