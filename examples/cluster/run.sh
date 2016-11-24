#!/bin/sh

docker-machine create local-consul -d virtualbox

eval $(docker-machine env local-consul)

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
    -p 53:53/udp consul:0.7.0 \
    agent -server -bootstrap -data-dir=/tmp/consul -client=0.0.0.0 -advertise=$(docker-machine ip local-consul)

docker-machine create -d virtualbox --swarm --swarm-master \
           --swarm-discovery="consul://$(docker-machine ip local-consul):8500" \
           --engine-label type=public \
           --engine-opt="cluster-store=consul://$(docker-machine ip local-consul):8500" \
           --engine-opt="cluster-advertise=eth1:2376" local-1


docker-machine create -d virtualbox --swarm  \
           --swarm-discovery="consul://$(docker-machine ip local-consul):8500" \
           --engine-label type=app \
           --engine-opt="cluster-store=consul://$(docker-machine ip local-consul):8500" \
           --engine-opt="cluster-advertise=eth1:2376" local-2 &

 
docker-machine create -d virtualbox --swarm \
           --swarm-discovery="consul://$(docker-machine ip local-consul):8500"  \
           --engine-label type=app \
           --engine-opt="cluster-store=consul://$(docker-machine ip local-consul):8500" \
           --engine-opt="cluster-advertise=eth1:2376" local-3 &
wait


MACHINES=$(docker-machine ls -q | grep -E local-.$)

for MACHINE in $MACHINES
do
    docker-machine ssh $MACHINE "
        sudo docker run -d \
            --privileged \
            --restart always \
            -e "constraint:node==$MACHINE" \
            --name consul-agent-$MACHINE \
            consul:0.7.0 agent --data-dir=/tmp/consul -rejoin -node $MACHINE -advertise $(docker-machine ip $MACHINE) -join $(docker-machine ip local-consul)" &
done
wait

for MACHINE in $MACHINES
do
    docker-machine ssh $MACHINE "
        sudo docker run -d \
            --privileged \
            --restart always \
            -e "constraint:node==$MASHINE" \
            --name registrator-agent-$MACHINE \
            -v /var/run/docker.sock:/tmp/docker.sock \
            gliderlabs/registrator:v7 -ip $(docker-machine ip $MACHINE) consul://$(docker-machine ip local-consul):8500" &
done
wait

eval $(docker-machine env --swarm local-1)
docker network create --driver overlay public

docker run -d \
    --privileged \
    --restart always \
    --name proxy \
    -p 80:80 \
    -e CONSUL_ADDR=$(docker-machine ip local-consul) \
    -e "constraint:type==public"
    --network public \
    dmitrovskiy/docker-nginx-consul-template:1.10.1-0.16.0-alpine

docker-compose up -d
docker-compose scale app=10
docker-compose logs -tf
