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
# Designed to run inside a Docker container with the grok_exporter source code mounted at /go/src/github.com/EdgewareRoad/grok_exporter
#========================================================================================

cd /go/src/github.com/EdgewareRoad/grok_exporter

export VERSION=$1
export BRANCH=$2

export VERSION_FLAGS="\
        -X github.com/EdgewareRoad/grok_exporter/exporter.Version=$VERSION
        -X github.com/EdgewareRoad/grok_exporter/exporter.BuildDate=$(date +%Y-%m-%d)
        -X github.com/EdgewareRoad/grok_exporter/exporter.Branch=$(git rev-parse --abbrev-ref $BRANCH)
        -X github.com/EdgewareRoad/grok_exporter/exporter.Revision=$(git rev-parse --short $BRANCH)
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
    go build -ldflags "$VERSION_FLAGS" -o "dist/grok_exporter-$VERSION.linux-amd64/grok_exporter" .
}


#--------------------------------------------------------------
# Release functions
#--------------------------------------------------------------

function release_linux_amd64 {
    echo "Building dist/grok_exporter-$VERSION.linux-amd64.zip"
    run_docker_linux_amd64
    create_zip_file grok_exporter-$VERSION.linux-amd64
}

#--------------------------------------------------------------
# main
#--------------------------------------------------------------

mkdir -p dist
rm -rf dist/grok_exporter-*
run_tests
release_linux_amd64
