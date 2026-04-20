# Copyright(c) The Maintainers of Nanvix.
# Licensed under the MIT License.

# =============================================================================
# nanvix/toolchain-rust
#
# Custom Rust fork (nanvix-x86 toolchain) with Nanvix OS target support.
#
# Build:
#   docker build -t ghcr.io/nanvix/toolchain-rust:1.0.0 .
#
# Verify:
#   docker run --rm ghcr.io/nanvix/toolchain-rust:1.0.0 rustc --version
# =============================================================================

ARG GCC_IMAGE=ghcr.io/nanvix/toolchain-gcc:latest
FROM ${GCC_IMAGE} AS gcc-sysroot

FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies for Rust compiler.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        libssl-dev \
        ninja-build \
        pkg-config \
        python3 \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy GCC sysroot (newlib headers/libs needed by Rust std build).
COPY --from=gcc-sysroot /opt/nanvix/toolchain-gcc /opt/nanvix/toolchain-gcc
ENV PATH="/opt/nanvix/toolchain-gcc/bin:${PATH}"

# Pinned Rust commit.
ARG RUST_COMMIT=f258dd9b4e305d565a3c9bf73d1ddb8bae621040

ENV PREFIX=/opt/nanvix/toolchain-rust

WORKDIR /build

# Clone Rust.
RUN git clone https://github.com/nanvix/rust /build/rust && \
    cd /build/rust && git checkout ${RUST_COMMIT}

# Build Rust toolchain.
RUN cd /build/rust && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="/opt/nanvix/toolchain-gcc" && \
    ./z build && \
    ./z install

# Copy cargo and other tools from stage2-tools-bin into stage2/bin.
RUN STAGE2_DIR="/build/rust/build/host/stage2" && \
    STAGE2_TOOLS_DIR="/build/rust/build/host/stage2-tools-bin" && \
    if [ ! -d "${STAGE2_TOOLS_DIR}" ]; then \
        STAGE2_DIR="/build/rust/build/x86_64-unknown-linux-gnu/stage2"; \
        STAGE2_TOOLS_DIR="/build/rust/build/x86_64-unknown-linux-gnu/stage2-tools-bin"; \
    fi && \
    if [ -d "${STAGE2_TOOLS_DIR}" ]; then \
        cp -f --remove-destination "${STAGE2_TOOLS_DIR}"/* "${STAGE2_DIR}/bin/"; \
    fi

# Copy Rust library source for -Zbuild-std support.
RUN mkdir -p "${PREFIX}/lib/rustlib/src/rust" && \
    cp -r /build/rust/library "${PREFIX}/lib/rustlib/src/rust/library"

# Copy stage2 as the toolchain root.
RUN STAGE2_DIR="/build/rust/build/host/stage2" && \
    if [ ! -d "${STAGE2_DIR}" ]; then \
        STAGE2_DIR="/build/rust/build/x86_64-unknown-linux-gnu/stage2"; \
    fi && \
    cp -a "${STAGE2_DIR}"/* "${PREFIX}/"

# =============================================================================
# Runtime stage — only the installed Rust toolchain prefix.
# =============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/nanvix/toolchain-rust /opt/nanvix/toolchain-rust

ENV PATH="/opt/nanvix/toolchain-rust/bin:${PATH}"

# Install rustup and link the custom toolchain.
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain none
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain link nanvix-x86 /opt/nanvix/toolchain-rust

# Smoke test.
RUN rustc --version && \
    rustup toolchain list | grep -q nanvix-x86

LABEL org.opencontainers.image.source="https://github.com/nanvix/toolchain-rust" \
      org.opencontainers.image.description="Nanvix custom Rust toolchain (nanvix-x86) with i686-unknown-nanvix target support"
