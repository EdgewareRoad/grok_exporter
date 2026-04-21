#!/bin/bash

set -e

if [[ $(go version) != *"go1.26"* ]] ; then
    echo "grok_exporter uses Go 1.26 Modules. Please use Go version >= 1.26." >&2
    echo "Version found is $(go version)" >&2
    exit 1
fi

if git status | grep example/ ; then
    echo "error: untracked files in example directory" >&2
    exit 1
fi

#=======================================================================================
# This is supposed to run on OS X.
# The Darwin release is built natively, Linux and Windows are built in a Docker container
#========================================================================================

cd /go/src/github.com/EdgewareRoad/grok_exporter

export VERSION=1.1.0-SNAPSHOT

export VERSION_FLAGS="\
        -X github.com/EdgewareRoad/grok_exporter/exporter.Version=$VERSION
        -X github.com/EdgewareRoad/grok_exporter/exporter.BuildDate=$(date +%Y-%m-%d)
        -X github.com/EdgewareRoad/grok_exporter/exporter.Branch=$(git rev-parse --abbrev-ref HEAD)
        -X github.com/EdgewareRoad/grok_exporter/exporter.Revision=$(git rev-parse --short HEAD)
"

#--------------------------------------------------------------
# Make sure all tests run.
#--------------------------------------------------------------

function run_tests {
    go fmt ./... && go vet ./... && go test ./...
}

#--------------------------------------------------------------
# Helper functions
#--------------------------------------------------------------

function enable_legacy_static_linking {
    # The compile script in the Docker image sets CGO_LDFLAGS to libonig.a, which should make grok_exporter
    # statically linked with the Oniguruma library. However, this doesn't work on Darwin and CentOS 6.
    # As a workaround, we set LDFLAGS directly in the header of oniguruma.go.
    sed -i.bak 's;#cgo LDFLAGS: -L/usr/local/lib -lonig;#cgo LDFLAGS: /usr/local/lib/libonig.a;' oniguruma/oniguruma.go
}

function revert_legacy_static_linking {
    if [ -f oniguruma/oniguruma.go.bak ] ; then
        mv oniguruma/oniguruma.go.bak oniguruma/oniguruma.go
    fi
}

function cleanup {
    revert_legacy_static_linking
}

# Make sure revert_legacy_static_linking is called even if a compile error makes this script terminate early
trap cleanup EXIT

function create_zip_file {
    OUTPUT_DIR=$1
    cp -a logstash-patterns-core/patterns dist/$OUTPUT_DIR
    cp -a example dist/$OUTPUT_DIR
    cd dist
    sed -i.bak s,/logstash-patterns-core/patterns,/patterns,g $OUTPUT_DIR/example/*.yml
    rm $OUTPUT_DIR/example/*.yml.bak
    zip --quiet -r $OUTPUT_DIR.zip $OUTPUT_DIR
    rm -r $OUTPUT_DIR
    cd ..
}

function run_docker_linux_amd64 {
    cd /go/src/github.com/EdgewareRoad/grok_exporter
    go build -ldflags "$VERSION_FLAGS" -o "dist/grok_exporter-$VERSION.linux-amd64/grok_exporter" .
}


#--------------------------------------------------------------
# Release functions
#--------------------------------------------------------------

function release_linux_amd64 {
    echo "Building dist/grok_exporter-$VERSION.linux-amd64.zip"
    #enable_legacy_static_linking
    run_docker_linux_amd64
    #revert_legacy_static_linking
    create_zip_file grok_exporter-$VERSION.linux-amd64
}

#--------------------------------------------------------------
# main
#--------------------------------------------------------------

rm -rf dist/grok_exporter-*
run_tests
release_linux_amd64
