# syntax=docker/dockerfile:1
ARG DEBIAN_FRONTEND=noninteractive

FROM --platform=$BUILDPLATFORM debian:bullseye AS builder-base
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libvlc-dev \
    libvlccore-dev \
    crossbuild-essential-arm64 \
    crossbuild-essential-armhf

COPY . /src
WORKDIR /src

FROM builder-base AS builder-amd64
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    make OS=Linux

FROM builder-base AS builder-arm64
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    make OS=Linux CC=aarch64-linux-gnu-gcc

FROM builder-base AS builder-armhf
ARG TARGETARCH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    make OS=Linux CC=arm-linux-gnueabihf-gcc

FROM alpine:latest AS artifacts
COPY --from=builder-amd64 /src/libspeed_hold_plugin.so /plugins/amd64/
COPY --from=builder-arm64 /src/libspeed_hold_plugin.so /plugins/arm64/
COPY --from=builder-armhf /src/libspeed_hold_plugin.so /plugins/armhf/
