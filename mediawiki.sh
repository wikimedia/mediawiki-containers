#!/bin/bash

# Simple shell script to start up MediaWiki + containers.
# Alternative to docker-compose, with automatic docker subnet detection to make
# this work on jessie or sid.

start () {
    set -e
    echo
    echo "Starting DNS container.."
    docker run -d \
        --name=dnsdock \
        -v /var/run/docker.sock:/run/docker.sock \
        tonistiigi/dnsdock
    DNS=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' dnsdock)

    echo
    echo "Starting mysql container.."
    docker run -d \
        --name=mysql \
        -v /var/lib/mediawiki-docker-compose/mediawiki-mysql:/var/lib/mysql:rw \
        -e MYSQL_ROOT_PASSWORD=password \
        --dns "$DNS" \
        mysql

    echo
    echo "Starting mediawiki container.."
    docker run -d \
        --name=mediawiki \
        -v `pwd`/mediawiki:/conf:ro \
        -v /var/lib/mediawiki-docker-compose/mediawiki-core:/data:rw \
        -e MEDIAWIKI_SITE_SERVER=//localhost \
        -e MEDIAWIKI_SITE_NAME=MediaWiki \
        -e MEDIAWIKI_SITE_LANG=en \
        -e MEDIAWIKI_ADMIN_USER=admin \
        -e MEDIAWIKI_ADMIN_PASS=rosebud \
        -e MEDIAWIKI_UPDATE=true \
        -e MEDIAWIKI_DB_USER=root \
        -e MEDIAWIKI_DB_HOST=mysql.docker \
        -e MEDIAWIKI_DB_PASSWORD=password \
        -e MEDIAWIKI_RESTBASE_URL=http://mediawiki-node-services.docker:7231/localhost/v1 \
        --dns "$DNS" \
        -p 80:80 \
        wikimedia/mediawiki

    echo
    echo "Starting mediawiki-node-services container.."
    docker run -d \
        --name=mediawiki-node-services \
        -v /var/lib/mediawiki-docker-compose/node-services:/data \
        -e MEDIAWIKI_API_URL=http://mediawiki.docker/api.php \
        --dns "$DNS" \
        -p 8142:8142 \
        -p 7231:7231 \
        wikimedia/mediawiki-node-services

    # Follow the mediawiki container logs
    docker logs -f mediawiki
}

stop () {
    # There is no state in the containers themselves, so always nuke them.
    docker rm -f mediawiki
    docker rm -f mediawiki-node-services
    docker rm -f mysql
    docker rm -f dnsdock
}


if [ -z "$1" ];then
    echo "Usage: $0 [start|stop]"
    exit 1
elif [ "$1" == "stop" ]; then
    stop
elif [ "$1" == "start" ]; then
    start
else
    echo "Invalid parameter: $1"
    exit 1
fi
