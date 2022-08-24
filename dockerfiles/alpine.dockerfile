ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS builder

RUN set -eux; \
    apk add --no-cache \
    build-base cmake bash autoconf automake pkgconf \
    libpcap libpcap-dev pcre pcre-dev \
    luajit luajit-dev check check-dev hwloc hwloc-dev \
    openssl3-dev libssl3 openssl3 zlib zlib-dev flex flex-dev bison \
    xz xz-dev libuuid linux-headers git \
    libunwind libunwind-dev libtool \
    ca-certificates util-linux-dev libtirpc-dev boost boost-dev ragel

ADD https://github.com/intel/hyperscan/archive/refs/tags/v5.4.0.tar.gz /tmp/hyperscan.tar.gz

RUN set -eux; \
    if [ "$(uname -m)" = 'x86_64*' ] || [ "$(uname -m)" = 'i*86' ]; then \
    mkdir -p /tmp/hyperscan_src/build; \
    tar -xvzf /tmp/hyperscan.tar.gz --strip-components=1 -C /tmp/hyperscan_src ; \
    ( \
    cd /tmp/hyperscan_src/build && \
    cmake /tmp/hyperscan_src && \
    make && \
    make install \
    ) ; \
    fi

ADD https://github.com/snort3/libdaq/archive/refs/tags/v3.0.9.tar.gz /tmp/libdaq.tar.gz

RUN set -eux; \
    mkdir -p /tmp/libdaq_src ; \
    tar -xvzf /tmp/libdaq.tar.gz --strip-components=1 -C /tmp/libdaq_src ; \
    (\
    cd /tmp/libdaq_src && \
    ./bootstrap && \
    ./configure && \
    make && \
    make install \
    ) ;

ADD https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-1.16.1.tar.gz /tmp/libdnet.tar.gz

RUN set -eux; \
    mkdir -p /tmp/libdnet_src ; \
    tar -xvzf /tmp/libdnet.tar.gz --strip-components=1 -C /tmp/libdnet_src ; \
    (\
    cd /tmp/libdnet_src && \
    ./configure && \
    make && \
    make install \
    ) ;

ADD https://github.com/rurban/safeclib/releases/download/v3.7.1/safeclib-3.7.1.tar.gz /tmp/libsafec.tar.gz

RUN set -eux; \
    mkdir -p /tmp/libsafec_src ; \
    tar -xvzf /tmp/libsafec.tar.gz --strip-components=1 -C /tmp/libsafec_src ; \
    ( \
    cd /tmp/libsafec_src && \
    ./configure && \
    make && \
    make install \
    ) ;

ADD https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 /tmp/jemalloc.tar.bz2

RUN set -eux; \
    mkdir -p /tmp/jemalloc_src ; \
    tar -xvjf /tmp/jemalloc.tar.bz2 --strip-components=1 -C /tmp/jemalloc_src ; \
    ( \
    cd /tmp/jemalloc_src && \
    ./configure && \
    make && \
    make install \
    ) ;

ADD https://github.com/snort3/snort3/archive/refs/tags/3.1.39.0.tar.gz /tmp/snort.tar.gz

RUN set -eux; \
    mkdir -p /tmp/snort_src ; \
    tar -xvzf /tmp/snort.tar.gz --strip-components=1 -C /tmp/snort_src ; \
    (\
    cd /tmp/snort_src && \
    ./configure_cmake.sh --prefix=/usr/local/snort --enable-jemalloc && \
    cd /tmp/snort_src/build && \
    make && \
    make install \
    ) ;

RUN set -eux; \
    git clone --depth 1 --single-branch --branch main https://github.com/shirkdog/pulledpork3.git /usr/local/pulledpork3 ; \
    mkdir -p /usr/local/etc/pulledpork/ ; \
    mkdir -p /usr/local/bin/pulledpork/ ; \
    cp /usr/local/pulledpork3/pulledpork.py /usr/local/bin/pulledpork/ ; \
    cp -r /usr/local/pulledpork3/lib/ /usr/local/bin/pulledpork/ ; \
    cp /usr/local/pulledpork3/etc/pulledpork.conf /usr/local/etc/pulledpork/ ;


FROM alpine:${ALPINE_VERSION}

RUN set -eux; \
    apk add --no-cache \
    libpcap pcre \
    luajit check hwloc \
    libssl3 openssl3 zlib flex bison \
    xz libuuid libtirpc \
    libunwind libtool \
    ca-certificates boost ragel \
    python3 py3-requests ; \
    mkdir -p /usr/local/etc/pulledpork/

COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/include/ /usr/local/include/
COPY --from=builder /usr/local/share/doc/ /usr/local/share/doc/
COPY --from=builder /usr/local/snort/ /usr/local/
COPY --from=builder /usr/local/bin/pulledpork/ /usr/local/bin/
COPY --from=builder /usr/local/etc/pulledpork/ /usr/local/etc/pulledpork/

RUN set -eux; \
    ldconfig /usr/local/lib ; \
    chmod +x /usr/local/bin/pulledpork.py ; \
    # setup user \
    addgroup -S snort && \
    adduser -S -G snort snort ; \
    install -g snort -o snort -m 5775 -d /var/log/snort ; \
    # prepare snort rules diretories \
    mkdir -p /usr/local/etc/rules ; \
    mkdir -p /usr/local/etc/so_rules/ ; \
    mkdir -p /usr/local/etc/lists/ ; \
    touch /usr/local/etc/rules/local.rules ; \
    touch /usr/local/etc/lists/default.blocklist

CMD [ "/usr/local/bin/snort", "-T", "-c", "/usr/local/etc/snort/snort.lua" ]
