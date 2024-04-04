# Varnish container image

This image is based on the official Varnish image and adds a [Prometheus exporter](https://github.com/jonnenauha/prometheus_varnish_exporter) and a configuration reloader script.

## Testing

You can test building and entering the container by running the following command :

````
dagger call container terminal
````
