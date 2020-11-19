FROM golang:1.14.10 as builder

RUN set -x \
 && cd src \
 && git clone https://github.com/jonnenauha/prometheus_varnish_exporter.git \
 && cd prometheus_varnish_exporter \
 && git fetch origin pull/64/head \
 && git checkout 46fa8a3f800d8cc2e0c95d0582aee50602f53633 \
 && ./build.sh 1.5.2+varnish_6.3

FROM debian:stretch-slim

ENV VARNISH_VERSION=6.3.1-1~stretch \
    COLLECTD_REPO=https://github.com/collectd/collectd/ \
    COLLECTD_TAG=collectd-5.9 \
    VARNISHKAFKA_REPO=https://github.com/camptocamp/varnishkafka/ \
    VARNISHKAFKA_TAG=master \
    PROMETHEUS_EXPORTER_RELEASE=1.5.2 \
    PROMETHEUS_EXPORTER_CHECKSUM=3ee8c4c59aea1c341b9f4750950f24c8e6d9670ae39ed44af273f08ea318ede8

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/50no-install-recommends
RUN echo 'APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/50no-install-suggests

COPY 50varnish /etc/apt/preferences.d/

# install varnish
RUN set -x \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install \
    ca-certificates \
    git \
    gnupg \
    dirmngr \
    inotify-tools \
    curl \
    jq \
    less \
    socat \
    procps \
    rsync \
    netcat-openbsd \
 && for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        apt-key adv --keyserver "${server}" --recv-keys 0xF4831166EFDCBABE && break || : ; \
    done \
 && echo "deb http://pkg.camptocamp.net/apt stretch/dev sysadmin varnish-6.3" > /etc/apt/sources.list.d/camptocamp.list \
 && apt-get update \
 && apt-get -y install \
    varnish=$VARNISH_VERSION \
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
    libmicrohttpd-dev \
    libprotobuf-c-dev protobuf-c-compiler \
    libyajl-dev \
    varnish-dev=$VARNISH_VERSION \
    libmicrohttpd12 \
    libprotobuf-c1 \
    libyajl2 \
 && git clone $COLLECTD_REPO -b $COLLECTD_TAG \
 && cd collectd && ./build.sh \
 && ./configure --enable-debug --disable-all-plugins --prefix=/usr/local CFLAGS="$(dpkg-buildflags --get CFLAGS) -Wall" CPPLAGS="$(dpkg-buildflags --get CPPFLAGS)" LDFLAGS="$(dpkg-buildflags --get LDFLAGS)" --enable-write_prometheus --enable-varnish --enable-unixsock --enable-log_logstash \
 && make && make check && make install && cd .. \
 && apt-get purge -y --auto-remove \
    build-essential dpkg-dev autoconf automake bison flex libtool \
    libmicrohttpd-dev \
    libprotobuf-c-dev protobuf-c-compiler \
    libyajl-dev \
    varnish-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* collectd/

# build & install varnishkafka
RUN set -x \
 && apt-get update \
 && apt-get -y install \
    build-essential \
    librdkafka-dev \
    libyajl-dev \
    librdkafka1 \
    libyajl2 \
    varnish-dev=$VARNISH_VERSION \
    zlib1g-dev \
 && git clone $VARNISHKAFKA_REPO -b $VARNISHKAFKA_TAG \
 && cd varnishkafka \
 && make && make install && cd .. \
 && apt-get purge -y --auto-remove \
    build-essential \
    librdkafka-dev \
    libyajl-dev \
    varnish-dev \
    zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* varnishkafka/

# install prometheus exporter
COPY --from=builder /go/src/prometheus_varnish_exporter/bin/build/prometheus_varnish_exporter-1.5.2+varnish_6.3.linux-amd64/prometheus_varnish_exporter /usr/local/bin/

ADD vcl-reload.sh /usr/local/sbin/
ADD vcl-reload-persistent.sh /usr/local/sbin/
ADD varnish-logger.sh /usr/local/sbin/
ADD collectd.conf /usr/local/etc/
