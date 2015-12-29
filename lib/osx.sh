#!/bin/bash

# mediawiki-containers OS X specific utils

set -e

MACHINE_NAME="mediawiki"

prepare_docker_machine() {
  if [ `docker-machine ls | grep ${MACHINE_NAME} | wc -l` == 0 ]; then
    echo "${MACHINE_NAME} machine doesn't exist. Creating."
    docker-machine create --driver virtualbox --virtualbox-memory 8096 ${MACHINE_NAME}
    docker-machine stop ${MACHINE_NAME}
    mkdir -p ${BASEDIR}
    VBoxManage sharedfolder add ${MACHINE_NAME} --name Basedir --hostpath ${BASEDIR} --automount
    docker-machine start ${MACHINE_NAME}
    docker-machine regenerate-certs -f ${MACHINE_NAME}
    eval "$(docker-machine env ${MACHINE_NAME})"
    docker-machine ssh ${MACHINE_NAME} "sudo mkdir -p ${BASEDIR}"
    docker-machine ssh ${MACHINE_NAME} "sudo mount -t vboxsf -o uid=999,gid=50 Basedir ${BASEDIR}"
  else
    machine_status=`docker-machine status mediawiki`
    if [ "$machine_status" == "Stopped" ]; then
      echo "Mediawiki machine is stopped. Starting."
      docker-machine start ${MACHINE_NAME}
    fi
    eval "$(docker-machine env ${MACHINE_NAME})"
  fi
}

get_machine_address() {
    MACHINE_ADDRESS=`docker-machine ip ${MACHINE_NAME}`
}