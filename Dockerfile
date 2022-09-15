# /!\ KEEP THE BASE IMAGE IN SYNC ACROSS ALL DOCKERFILES /!\
FROM varnish:7.1.1

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

ADD varnish-configuration-loader /usr/local/sbin/
