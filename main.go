package main

import (
	"context"
	"fmt"
	"strings"
	"time"
	"varnish/internal/dagger"
)

const (
	// Varnish container registry
	ImageRegistry string = "docker.io"
	// Varnish container repository
	ImageRepository string = "library/varnish"
	// Varnish container tag
	ImageTag string = "7.5.0"
	// Varnish container digest
	ImageDigest string = "sha256:ca2fcecb439f71a3546d025c65857591281a1596c44e8cb816905aa4d1864b61"

	// Varnish Prometheus exporter version
	PrometheusExporterVersion string = "1.6.1"

	// jq version
	JqVersion string = "1.7.1"
)

// Varnish
type Varnish struct{}

// Get a Varnish container
func (varnish *Varnish) Container(
	ctx context.Context,
	// Platform to get container for
	// +optional
	platform dagger.Platform,
) (*dagger.Container, error) {
	prometheusExporter, err := varnish.PrometheusExporter(PrometheusExporterVersion).Overlay(ctx, platform, "")

	if err != nil {
		return nil, fmt.Errorf("failed to get Prometheus Exporter overlay: %s", err)
	}

	jq := dag.Jq(JqVersion).Overlay(dagger.JqOverlayOpts{Platform: platform})
	configurationLoaderScript := dag.CurrentModule().Source().File("varnish-configuration-loader")

	container := dag.Container(dagger.ContainerOpts{Platform: platform}).
		From(ImageRegistry+"/"+ImageRepository+":"+ImageTag+"@"+ImageDigest).
		WithDirectory("/", prometheusExporter).
		WithDirectory("/", jq).
		WithFile("/usr/local/bin/varnish-configuration-loader", configurationLoaderScript, dagger.ContainerWithFileOpts{
			Owner:       "root:root",
			Permissions: 0755,
		})

	return container, nil
}

// Varnish Prometheus Exporter
type VarnishPrometheusExporter struct {
	// +private
	Version string
}

// Varnish Prometheus Exporter constructor
func (*Varnish) PrometheusExporter(
	// Varnish Prometheus exporter version to get
	version string,
) *VarnishPrometheusExporter {
	prometheusExporter := &VarnishPrometheusExporter{
		Version: version,
	}

	return prometheusExporter
}

// Get Varnish Prometheus Exporter executable binary
func (prometheusExporter *VarnishPrometheusExporter) Binary(
	ctx context.Context,
	// Platform to get Varnish Prometheus exporter for
	// +optional
	platform dagger.Platform,
) (*dagger.File, error) {
	if platform == "" {
		defaultPlatform, err := dag.DefaultPlatform(ctx)

		if err != nil {
			return nil, fmt.Errorf("failed to get platform: %s", err)
		}

		platform = defaultPlatform
	}

	platformElements := strings.Split(string(platform), "/")

	os := platformElements[0]
	arch := platformElements[1]

	source := dag.Git("https://github.com/jonnenauha/prometheus_varnish_exporter.git").
		Tag(prometheusExporter.Version)

	commit, err := source.Commit(ctx)

	if err != nil {
		return nil, fmt.Errorf("failed to get commit hash: %s", err)
	}

	binary := dag.Golang().
		RedhatContainer().
		WithEnvVariable("GOOS", os).
		WithEnvVariable("GOARCH", arch).
		WithMountedDirectory(".", source.Tree()).
		WithExec([]string{"go", "build", "-ldflags", fmt.Sprintf("-X 'main.Version=%s' -X 'main.VersionHash=%s' -X 'main.VersionDate=%s'", prometheusExporter.Version, commit, time.Now().Format("2006-01-02 15:04:05 -07:00"))}).
		File("prometheus_varnish_exporter")

	return binary, nil
}

// Get a root filesystem overlay with Varnish Prometheus Exporter
func (prometheusExporter *VarnishPrometheusExporter) Overlay(
	ctx context.Context,
	// Platform to get Varnish Prometheus Exporter for
	// +optional
	platform dagger.Platform,
	// Filesystem prefix under which to install Varnish Prometheus Exporter
	// +optional
	prefix string,
) (*dagger.Directory, error) {
	if prefix == "" {
		prefix = "/usr/local"
	}

	binary, err := prometheusExporter.Binary(ctx, platform)

	if err != nil {
		return nil, fmt.Errorf("failed to get Varnish Prometheus Exporter binary: %s", err)
	}

	overlay := dag.Directory().
		WithDirectory(prefix, dag.Directory().
			WithFile("bin/prometheus-varnish-exporter", binary),
		)

	return overlay, nil
}
