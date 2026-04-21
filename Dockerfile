ARG VERSION=1.1.0-SNAPSHOT
ARG BRANCH=main

FROM ubuntu:25.10

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    zip \
    libonig-dev

RUN wget https://dl.google.com/go/go1.26.2.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.26.2.linux-amd64.tar.gz
ENV GOROOT=/usr/local/go
ENV PATH=$GOROOT/bin:$PATH

RUN mkdir -p /go/src/github.com/EdgewareRoad/grok_exporter
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH

WORKDIR /go/src/github.com/EdgewareRoad/grok_exporter
RUN git init
RUN git remote add origin https://github.com/EdgewareRoad/grok_exporter
RUN git fetch origin
RUN git checkout $BRANCH
RUN git submodule update --init --recursive

WORKDIR /go/src/github.com/EdgewareRoad/grok_exporter/hack
ENTRYPOINT [ "/go/src/github.com/EdgewareRoad/grok_exporter/hack/release.sh", "$VERSION", "$BRANCH" ] 
