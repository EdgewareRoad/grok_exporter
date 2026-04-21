FROM ubuntu:25.10

ARG VERSION=1.1.0-SNAPSHOT
ARG BRANCH=master
ARG REVISION=unknown

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

ENTRYPOINT [ "/workspace/hack/release.sh", "$VERSION", "$BRANCH", "$REVISION", "/workspace/dist" ] 
