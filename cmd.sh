#!/bin/bash

export $(egrep -v '^#' .env | xargs)
args=("$@")

export TAG_RELEASE=$(date +"%y.%m%d.%S")
export SOLODEV_RELEASE=$TAG_RELEASE
export AWS_PROFILE=develop

relay(){
    docker-compose up --build relay-node
}

block(){
    docker-compose up --build block-node
}

tag(){
    VERSION="${args[1]}"
    git tag -a v${VERSION} -m ".1"
    git push --tags
}

clean() {
    down
    docker stop $(docker ps -a -q)
    docker volume prune --force
    docker image prune --force
    docker kill $(docker ps -q)
    docker rmi $(docker images -a -q)
}

sync(){
    echo "Upload Blockchain to S3"
    cd blockfs/testnet/
    tar -czvf db.tar.gz *
    aws s3 cp db.tar.gz s3://cardano-node/testnet/db.tar.gz
}

ami(){
    cd devops/ami
    ./build.sh config cardano-packer.json
}

chef(){
    cd devops/chef
    ./package.sh
}

cft(){
    cd devops/cloudformation
    ./deploy.sh
}

build(){
    docker build --file devops/docker/Dockerfile --tag "$DOCKER_REPO:latest" --label software="cardano-node" --build-arg APP_ENV="prod" .
    ./devops/docker/build.sh $DOCKER_REPO $DOCKER_REPO:latest
    docker push "$DOCKER_REPO:latest"
    docker pull "$DOCKER_REPO"
}

$*