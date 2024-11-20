## ActivityWatch Server Docker Image

This repository contains a Dockerfile for building a Docker image for [the ActivityWatch Server](https://github.com/ActivityWatch/aw-server-rust).

## Usage

```yaml
  aw-server:
    image: ghcr.io/ry0tak/aw-server-docker:latest
    ports:
      # This interface has no authentication. Do not expose this port to the public internet.
      - 5600:5600
```