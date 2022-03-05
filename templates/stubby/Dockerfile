#######################
#
# OpenSSL
#
#######################
FROM debian:buster-slim as openssl-install

ENV VERSION_OPENSSL={{ stubby.openssl_version }} \
    SHA256_OPENSSL={{ stubby.openssl_sha256 }} \
    SOURCE_OPENSSL={{ stubby.openssl_source }} \
    OPGP_OPENSSL={{ stubby.openssl_opgp }}

WORKDIR /tmp/src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN set -e -x && \
    build_deps="build-essential ca-certificates curl dirmngr gnupg libidn2-0-dev libssl-dev" && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        gnupg \
        libidn2-0-dev \
        libssl-dev

# Download and extract openssl
RUN set -e -x && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz -o openssl.tar.gz && \
    echo "${SHA256_OPENSSL} ./openssl.tar.gz" | sha256sum -c - && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz.asc -o openssl.tar.gz.asc && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    ( gpg --no-tty --keyserver ipv4.pool.sks-keyservers.net --recv-keys "${OPGP_OPENSSL}" \
    || gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "${OPGP_OPENSSL}" \
    || gpg --no-tty --keyserver pgp.mit.edu --recv-keys "${OPGP_OPENSSL}" \
    || gpg --no-tty --keyserver keyserver.pgp.com --recv-keys "${OPGP_OPENSSL}" ) && \
    gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
    tar xzf openssl.tar.gz

# Compile openssl
RUN set -e -x && \
    cd "${VERSION_OPENSSL}" && \
    ./config \
        -Wl,-rpath=/opt/openssl/lib \
        --prefix=/opt/openssl \
        --openssldir=/opt/openssl \
        enable-ec_nistp_64_gcc_128 \
        -DOPENSSL_NO_HEARTBEATS \
        no-weak-ssl-ciphers \
        no-ssl2 \
        no-ssl3 \
        shared \
        -fstack-protector-strong && \
    make depend && \
    make && \
    make install_sw

# Cleanup
RUN set -e -x && \
    apt-get purge -y --auto-remove \
      $build_deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*

#######################
#
# Stubby
#
#######################
FROM debian:buster-slim as stubby-install

LABEL maintainer="nioorg"

ENV GETDNS_VERSION "{{ stubby.getdns_version }}"

WORKDIR /tmp/src

# Using pipe fails on any command failed
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Clean output only during build
ARG DEBIAN_FRONTEND=noninteractive

# Download stubby
RUN set -e -x && \
    git_deps="ca-certificates git" && \
    apt-get update && apt-get install --no-install-recommends -y $git_deps
RUN git clone https://github.com/getdnsapi/getdns.git && \
    cd getdns && \
    git checkout "${GETDNS_VERSION}" && \
    git submodule update --init

# Install dependencies
RUN set -e -x && \
    build_deps="ca-certificates gcc make cmake check libsystemd-dev build-essential libssl-dev libyaml-dev" && \
    apt-get update && apt-get install --no-install-recommends -y $build_deps

COPY --from=openssl-install /opt/openssl /opt/openssl

# Install stubby
RUN set -e -x && \
    cd /tmp/src/getdns && \
    mkdir build && \
    cd build && \
    cmake \
        -DBUILD_STUBBY=ON \
        -DENABLE_STUB_ONLY=ON \
        -DCMAKE_INSTALL_PREFIX=/opt/stubby \
        -DOPENSSL_INCLUDE_DIR=/opt/openssl \
        -DOPENSSL_CRYPTO_LIBRARY=/opt/openssl/lib/libcrypto.so \
        -DOPENSSL_SSL_LIBRARY=/opt/openssl/lib/libssl.so \
        -DUSE_LIBIDN2=OFF \
        -DBUILD_LIBEV=OFF \
        -DBUILD_LIBEVENT2=OFF \
        -DBUILD_LIBUV=OFF .. && \
    make && \
    make install

# Clean image
RUN set -e -x && \
    apt-get purge -y --auto-remove \
        $git_deps \
        $build_deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*

#######################
#
# Runtime image
#
#######################
FROM debian:buster-slim 

LABEL maintainer="nioorg"

ENV STUBBY_INSTALLATION_DIR "/opt/stubby"
ENV STUBBY_CONFIGURATION "/etc/stubby/stubby.yml"

COPY --from=openssl-install /opt/openssl /opt/openssl
COPY --from=stubby-install /opt/stubby ${STUBBY_INSTALLATION_DIR}

# Clean output only during build
ARG DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN set -e -x && \
    apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates \
#       TODO to check if required
#       dns-root-data \
#       ldnsutils \
        libyaml-0-2

# Configuration: worksdir
RUN mkdir -m 0770 /app

# Set capability to bind on privileged port
RUN set -e -x && \
    apt-get update && apt-get install --no-install-recommends -y \
        libcap2-bin && \
    setcap 'cap_net_bind_service=+ep' ${STUBBY_INSTALLATION_DIR}/bin/stubby

# Clean image
RUN set -e -x && \
    apt-get purge -y --auto-remove \
        libcap2-bin && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*

# Copy the entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

WORKDIR /app

ENTRYPOINT [ "/app/entrypoint.sh" ]

CMD [ "stubby", "-v", "2" ]
