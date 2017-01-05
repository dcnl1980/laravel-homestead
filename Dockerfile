FROM ubuntu:16.04
MAINTAINER Chris van Steenbergen <cvsteenbergen@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install packages
ADD provision.sh /provision.sh
ADD serve.sh /serve.sh

ADD supervisor.conf /etc/supervisor/conf.d/supervisor.conf

ADD local.medsen-it.conf /etc/apache2/sites-enabled/local.medsen-it.conf

RUN chmod +x /*.sh

RUN ./provision.sh

EXPOSE 80 81 22 1025 8025 35729 9876
CMD ["/usr/bin/supervisord"]
