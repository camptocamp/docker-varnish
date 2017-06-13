FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/50no-install-recommends
RUN echo 'APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/50no-install-suggests

COPY 50varnish /etc/apt/preferences.d/

RUN set -x \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install \
    gnupg \
    dirmngr \
 && apt-key adv --keyserver hkps.pool.sks-keyservers.net --recv-keys 0xF4831166EFDCBABE \
 && echo "deb http://pkg.camptocamp.net/apt stretch/dev sysadmin varnish-5.0" > /etc/apt/sources.list.d/camptocamp.list \
 && apt-get update \
 && apt-get -y install \
    varnish \
    varnishkafka \
    rsync \
 && apt-get purge -y --auto-remove \
    gnupg \
    dirmngr \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD vcl-reload.sh /usr/local/sbin/
ADD varnish-logger.sh /usr/local/sbin/

ADD varnishkafka.conf /etc/varnishkafka/
