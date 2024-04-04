package main

import (
	"context"
)

const (
	version                   = "7.5.0"
	prometheusExporterVersion = "1.6.1"
	jqVersion                 = "1.7.1"
)

type Varnish struct{}

func (v *Varnish) Container() *Container {
	binaryFileOpts := ContainerWithFileOpts{
		Owner:       "root:root",
		Permissions: 0755,
	}

	exporter := dag.Container().
		From("registry.access.redhat.com/ubi9/ubi").
		WithWorkdir("/home").
		WithEntrypoint([]string{"bash", "-c"}).
		WithFile("prometheus-exporter.tar.gz", dag.HTTP("https://github.com/jonnenauha/prometheus_varnish_exporter/releases/download/"+prometheusExporterVersion+"/prometheus_varnish_exporter-"+prometheusExporterVersion+".linux-amd64.tar.gz")).
		WithExec([]string{"tar -xzvf prometheus-exporter.tar.gz"}).
		File("prometheus_varnish_exporter-" + prometheusExporterVersion + ".linux-amd64/prometheus_varnish_exporter")

	return dag.Container().
		From("docker.io/varnish:"+version).
		WithFile("/usr/local/bin/prometheus_varnish_exporter", exporter, binaryFileOpts).
		WithFile("/usr/local/bin/jq", dag.HTTP("https://github.com/jqlang/jq/releases/download/jq-"+jqVersion+"/jq-linux-amd64"), binaryFileOpts).
		WithFile("/usr/local/bin/varnish-configuration-loader", dag.Host().File("varnish-configuration-loader"), binaryFileOpts)
}

func (v *Varnish) Publish(ctx context.Context, registry string, username string, password string, repository string, tag string) (string, error) {
	return v.Container().WithRegistryAuth(registry, username, dag.SetSecret("registry-password", password)).Publish(ctx, registry+"/"+repository+":"+tag)
}
