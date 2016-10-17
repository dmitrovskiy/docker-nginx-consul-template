FROM nginx:1.10.1-alpine

MAINTAINER Vladimir Dmitrovskiy "vladimir@tep.io"

COPY run.sh /root/run.sh

EXPOSE 80 443

CMD ["/root/run.sh"]
