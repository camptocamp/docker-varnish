# /!\ KEEP THE BASE IMAGE IN SYNC ACROSS ALL DOCKERFILES /!\
FROM docker.io/varnish:7.4.2

USER root

RUN set -x \
 && apt-get update \
 && apt-get -y install \
    jq \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER varnish

ADD varnish-configuration-loader /usr/local/sbin/
