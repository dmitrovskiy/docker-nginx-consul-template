FROM nginx:1.10.1-alpine

MAINTAINER Vladimir Dmitrovskiy "vladimir@tep.io"

ENV CONSUL_TEMPLATE_VERSION=0.16.0

RUN apk add --update --virtual tobedeleted \
    wget \
    unzip

RUN wget --no-check-certificate https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
    unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -d /usr/local/bin

#cleaning up
RUN apk del --purge tobedeleted && \
    rm ./consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip

COPY . /app/
WORKDIR /app/

EXPOSE 80 443

CMD ["/app/run.sh"]
