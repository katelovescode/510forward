# docker role

Installs Docker CE on amd64 and arm64 hosts.

## What it does

- Adds the Docker apt repository and GPG key
- Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, and the Compose plugin
- Handles both amd64 (norville, dorothy) and arm64 (andromeda) architectures

## Why Docker CE and not the distro package

The distro-packaged `docker.io` lags significantly behind upstream releases and has a different daemon configuration. Docker CE from the upstream apt repo is the standard for production and homelab use. The snap package is avoided because it runs in a confined environment that causes friction with bind mounts and host paths.
