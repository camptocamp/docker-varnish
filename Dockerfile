FROM debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/50no-install-recommends
RUN echo 'APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/50no-install-suggests

COPY 50varnish /etc/apt/preferences.d/

# install varnish
RUN set -x \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install \
    gnupg \
    dirmngr \
    inotify-tools \
    curl \
    socat \
    procps \
    netcat-openbsd \
 && for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        apt-key adv --keyserver "${server}" --recv-keys 0xF4831166EFDCBABE && break || : ; \
    done \
 && echo "deb http://pkg.camptocamp.net/apt stretch/dev sysadmin varnish-5.1" > /etc/apt/sources.list.d/camptocamp.list \
 && apt-get update \
 && apt-get -y install \
    varnish=5.1.3-1~stretch \
    rsync \
 && apt-get purge -y --auto-remove \
    gnupg \
    dirmngr \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


# build & install collectd
RUN set -x \
 && apt-get update \
 && apt-get -y install \
    build-essential dpkg-dev autoconf automake bison flex libtool \
    ca-certificates \
    git \
    libmicrohttpd-dev \
    libprotobuf-c-dev protobuf-c-compiler \
    libyajl-dev \
    varnish-dev \
    libmicrohttpd12 \
    libprotobuf-c1 \
    libyajl2 \
 && git clone https://github.com/collectd/collectd/ -b collectd-5.8 \
 && cd collectd && ./build.sh \
 && ./configure --enable-debug --disable-all-plugins --prefix=/usr/local CFLAGS="$(dpkg-buildflags --get CFLAGS) -Wall" CPPLAGS="$(dpkg-buildflags --get CPPFLAGS)" LDFLAGS="$(dpkg-buildflags --get LDFLAGS)" --enable-write_prometheus --enable-varnish --enable-unixsock --enable-log_logstash \
 && make && make check && make install && cd .. \
 && apt-get purge -y --auto-remove \
    build-essential dpkg-dev autoconf automake bison flex libtool \
    ca-certificates \
    git \
    libmicrohttpd-dev \
    libprotobuf-c-dev protobuf-c-compiler \
    libyajl-dev \
    varnish-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* collectd/

ADD vcl-reload.sh /usr/local/sbin/
ADD vcl-reload-persistent.sh /usr/local/sbin/
ADD varnish-logger.sh /usr/local/sbin/
ADD collectd.conf /usr/local/etc/
