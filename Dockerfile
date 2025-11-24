# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Avoid prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Install build essentials
RUN apt-get update && \
    apt-get install -y build-essential cmake git pkg-config libvlc-dev && \
    apt-get clean

# Set working directory inside the container
WORKDIR /app

# Copy current project into container
COPY . /app
