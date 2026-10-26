# Lint and test tools for cicd.bash, which runs those 2 steps in this image
# unless given --no-container. Sync and publish stay on the host.
#
# shcl and gitniblet are built from pinned commits on their dev branches, never a
# release. cicd/bump-pins.bash moves SHCL_REV and GITNIBLET_REV to the newest ones.
# The tag is a hash of this folder's files, so any edit here means a new image.
#
# Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
# SPDX-License-Identifier: MIT

ARG BASE=debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f
ARG SHCL_REV=795f3119797652f34bfb9d29cfe065dce5eed8ca
ARG GITNIBLET_REV=1ffd2afc507528e6b51fb2e3505e5d558238452e

FROM ${BASE} AS build
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates curl git xz-utils gcc libc6-dev \
	&& rm -rf /var/lib/apt/lists/*

# Parallel jobs for cargo and go, from cicd.bash's CPU cap.
ARG JOBS=1

ARG SHCL_REV
ARG GITNIBLET_REV

ARG RUSTUP_VER=1.29.1
ARG RUSTUP_SHA256=dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71
# The go line in gitniblet's go.mod can ask for a newer toolchain, which go fetches
# and checks against the checksum database.
ARG GO_VER=1.26.10
ARG GO_SHA256=ccfe7ae822d2c2f41f4fe7c956199967a4dac22d0ee0d2b2bfdb440aab3b20c5
ARG SHELLCHECK_VER=0.11.0
ARG SHELLCHECK_SHA256=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
ARG NODE_VER=22.23.2
ARG NODE_SHA256=d60acfe00a2932254bb0ad20e01b0d74397a0875595de719654b214f4b03f307

WORKDIR /tmp/dl
RUN curl -fsSLo go.tgz "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" \
	&& echo "${GO_SHA256}  go.tgz" | sha256sum -c - \
	&& tar -C /opt -xzf go.tgz \
	&& curl -fsSLo rustup-init "https://static.rust-lang.org/rustup/archive/${RUSTUP_VER}/x86_64-unknown-linux-gnu/rustup-init" \
	&& echo "${RUSTUP_SHA256}  rustup-init" | sha256sum -c - \
	&& chmod +x rustup-init \
	&& RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo ./rustup-init -y --no-modify-path --profile minimal --default-toolchain none \
	&& curl -fsSLo sc.txz "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VER}/shellcheck-v${SHELLCHECK_VER}.linux.x86_64.tar.xz" \
	&& echo "${SHELLCHECK_SHA256}  sc.txz" | sha256sum -c - \
	&& mkdir -p /out && tar -C /out --strip-components=1 -xJf sc.txz "shellcheck-v${SHELLCHECK_VER}/shellcheck" \
	&& curl -fsSLo node.txz "https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-linux-x64.tar.xz" \
	&& echo "${NODE_SHA256}  node.txz" | sha256sum -c - \
	&& mkdir /opt/node && tar -C /opt/node --strip-components=1 -xJf node.txz \
	&& cd / && rm -rf /tmp/dl

ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:/opt/go/bin:/opt/node/bin:${PATH}

# The toolchain shcl's own rust-toolchain.toml names, without the cross targets
# it lists, which this build doesn't need.
RUN git init -q /src/shcl && cd /src/shcl \
	&& git fetch -q --depth 1 https://github.com/yottacore/shcl "${SHCL_REV}" && git checkout -q FETCH_HEAD \
	&& toolchain="$(sed -n 's/^channel = "\(.*\)"/\1/p' rust-toolchain.toml | head -n 1)" \
	&& rustup toolchain install --profile minimal "${toolchain}" \
	&& cd source/rust && RUSTUP_TOOLCHAIN="${toolchain}" cargo build -q --release --locked --bin shcl -j "${JOBS}" \
	&& cp target/release/shcl /out/

RUN git init -q /src/gitniblet && cd /src/gitniblet \
	&& git fetch -q --depth 1 https://github.com/yottacore/gitniblet "${GITNIBLET_REV}" && git checkout -q FETCH_HEAD \
	&& cd source && CGO_ENABLED=0 go build -mod=vendor -p "${JOBS}" -trimpath -o /out/gitniblet ./cmd/gitniblet

# markdownlint-cli and its dependencies from the lock file, each by its integrity hash.
COPY package.json package-lock.json /opt/mdl/
RUN cd /opt/mdl && npm ci --no-fund --no-audit --ignore-scripts


FROM ${BASE}
ARG SHCL_REV
ARG GITNIBLET_REV
RUN apt-get update \
	&& apt-get install -y --no-install-recommends git \
	&& rm -rf /var/lib/apt/lists/*
COPY --from=build /out/ /usr/local/bin/
COPY --from=build /opt/node/bin/node /usr/local/bin/node
COPY --from=build /opt/mdl /opt/mdl
RUN ln -s /opt/mdl/node_modules/.bin/markdownlint /usr/local/bin/markdownlint \
	&& mkdir -m 1777 /home/ci

# Runs as the caller's uid, which has no passwd entry here.
ENV HOME=/home/ci \
	NIT_PIN_SHCL=${SHCL_REV} \
	NIT_PIN_GITNIBLET=${GITNIBLET_REV}
WORKDIR /
