# /!\ KEEP THE BASE IMAGE IN SYNC ACROSS ALL DOCKERFILES /!\
FROM docker.io/varnish:7.2.0

USER root

RUN set -x \
 && apt-get update \
 && apt-get -y install \
    curl \
    jq \
    less \
    procps \
    netcat-openbsd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER varnish

ADD varnish-configuration-loader /usr/local/sbin/
