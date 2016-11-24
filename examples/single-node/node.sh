#!/bin/sh

MACHINE="local"
docker-machine create $MACHINE -d virtualbox

eval $(docker-machine env $MACHINE)
docker network create --driver bridge public

docker run -d \
    --privileged \
    --restart always \
    --name consul \
    -p 8300:8300 \
    -p 8301:8301 \
    -p 8301:8301/udp \
    -p 8302:8302/udp \
    -p 8302:8302 \
    -p 8400:8400 \
    -p 8500:8500 \
    -p 53:53/udp \
    consul:0.7.0 \
    agent -server -bootstrap -data-dir=/tmp/consul -client=0.0.0.0 -advertise=$(docker-machine ip local-consul)


docker run -d \
    --privileged \
    --restart always \
    --name registrator \
    -v /var/run/docker.sock:/tmp/docker.sock \
    gliderlabs/registrator:v7 -ip $(docker-machine ip $MACHINE) consul://$(docker-machine ip $MACHINE):8500

docker run -d \
    --privileged \
    --restart always \
    --name proxy \
    -p 80:80 \
    -e "CONSUL_ADDR=$(docker-machine ip $MACHINE)" \
    --network public \
    dmitrovskiy/docker-nginx-consul-template:1.10.1-0.16.0-alpine

docker-compose up -d
docker-compose scale app=10
docker-compose logs -tf
