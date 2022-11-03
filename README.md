Varnish docker image
========================

[![By Camptocamp](https://img.shields.io/badge/by-camptocamp-fb7047.svg)](http://www.camptocamp.com)

Run a simple varnish service.


# Build

Clone the repository and :

    docker build . -t varnish:7.1.1_c2c.1

    docker build --build-arg varnish_exporter_version=1.6.1 -f Dockerfile-prometheus-exporter . -t varnish:7.1.1_prometheus-exporter.1.6.1
