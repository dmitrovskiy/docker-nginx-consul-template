# Docker consul-template&nginx reverse proxy

Inspired by [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy)   
This solution is intended to be used with [Swarm Cluster](https://docs.docker.com/swarm/install-manual/)   
[Consul-Template](https://github.com/hashicorp/consul-template) is used for listening [Consul](https://github.com/hashicorp/consul) events and generating nginx config   

## Usage

To run it, you need to have next environment:

- [Consul](https://github.com/hashicorp/consul), [DockerHub](https://hub.docker.com/_/consul/)
- [Registrator](https://github.com/gliderlabs/registrator), [DockerHub](https://hub.docker.com/r/gliderlabs/registrator/)

When requirements are satisfied, run this:

```bash
docker run -d \
    --privileged \
    --restart always \
    --name proxy \
    -p 80:80 \
    -e CONSUL_ADDR=$(docker-machine ip local-consul) \
    -e "constraint:type==public"
    --network public \
    dmitrovskiy/docker-nginx-consul-template:1.10.1-0.16.0-alpine
```

An image exposes as 80, as 443(https)

### Environment variables

- `CONSUL_ADDR` - ip address of Consul location
- `CONSUL_PORT` - Consul port. By default 8500
- `IS_HTTPS` - set as "1" if you want to use https. Also required `CERT` variable to be set
- `CERT` - name of certificate. For instance, if `test.com` is set, it will try to use `/etc/nginx/certs/test.com.crt` and `/etc/nginx/certs/test.com.key`. And of course you need to volume them or COPY before run 

### Running services

```yaml
version: "2"
services:
    app:
        image: nginx
        ports:
            - 80
        environment:
            - 'SERVICE_80_NAME=web/app'
            - 'SERVICE_80_TAGS="Name":"app.local"'
            - 'constraint:type==app'
        networks:
            - public
networks:
    public:
        external: true
```

Running a service, there are some points which need to consider:

- You should declare service ports which are needed to be proxy reversed
- Each Docker-Compose service port is a separate service for Consul, so use `SERVICE_$PORT` prefix
- `SERVICE_80_NAME` - consul service name declaration. Should have `web/` prefix
- `SERVICE_80_TAGS` - consul service tags. 
This solution is used to declare JSON options. Currently only `Name` supported which is needed for server domain definition

## Contributing
If you any ideas or PR, I would be happy to disscuss it! :)
