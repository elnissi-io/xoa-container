# Xen-Orchestra Dockerized Container

Originally forked from [ronivay/xen-orchestra-docker](https://github.com/ronivay/xen-orchestra-docker).

Docker Hub and Quay.io badges display the popularity and size of the Docker container:
- Docker Hub: ![Image Pulls](https://img.shields.io/quay/pulls/elnissi-io/xoa-container.svg) [Link](https://hub.docker.com/r/elnissi-io/xoa-container)
- Quay.io: ![Image Size & Pulls](https://img.shields.io/quay/image-size/elnissi-io/xoa-container/latest) [Link](https://quay.io/elnissi-io/xoa-container)

CI Status: ![Build Status](https://github.com/elnissi-io/xoa-container/actions/workflows/build.yml/badge.svg?branch=master) [GitHub Actions](https://github.com/elnissi-io/xoa-container/actions?query=workflow%3Abuild)

This repository contains files to build Xen-Orchestra community edition docker container with all features and plugins installed.

The latest tag is a weekly build from Xen Orchestra sources' master branch. Images are also tagged based on xo-server version.

Xen-Orchestra is a Web-UI for managing your existing XenServer infrastructure. Learn more at [xen-orchestra.com](https://xen-orchestra.com/).

Xen-Orchestra offers a supported version of their product in an appliance (not running Docker though), which is highly recommended for those working with larger infrastructure.

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/elnissi-io/xoa-container
   ```

2. Build the Docker container manually:
   ```bash
   docker build -t xoa-container .
   ```

3. Or pull from quay:
   ```bash
   docker pull quay.io/elnissi-io/xoa-container
   ```

4. Run it with default values for testing purposes:
   ```bash
   docker run -itd -p 80:80 elnissi-io/xoa-container
   ```
   Xen-Orchestra is now accessible at http://your-ip-address. Default credentials: admin@admin.net/admin

5. For use beyond testing, it's suggested to mount data paths from your host to preserve data:
   ```bash
   docker run -itd -p 80:80 -v /path/to/data/xo-server:/var/lib/xo-server -v /path/to/data/redis:/var/lib/redis elnissi-io/xoa-container
   ```

6. Add `--stop-timeout` to allow multiple services inside a single container to shut down gracefully when the container is stopped. The default timeout of 10 seconds can be too short.

7. In recent Docker versions, containers run without root privileges or with reduced privileges. For XenOrchestra to mount NFS/SMB shares for Remotes from within Docker, run Docker with privileges using the `--cap-add sys_admin --cap-add dac_read_search` option or `--privileged` for all privileges. Additional steps are required for systems using AppArmor or SELinux.

For AppArmor, add `--security-opt apparmor:unconfined`.

Here is an example command for running the app in a Docker container with automatic container start on boot/crash, enough capabilities to mount NFS shares, and sufficient time for proper service shutdown:
```bash
docker run -itd \
  --stop-timeout 60 \
  --restart unless-stopped \
  --cap-add sys_admin \
  --cap-add dac_read_search \
  --security-opt apparmor:unconfined \
  -p 80:80 \
  -v /path/to/data/xo-server:/var/lib/xo-server \
  -v /path/to/data/redis:/var/lib/redis \
  elnissi-io/xoa-container
```

You may also use Docker Compose. Copy the configuration from the example `docker-compose.yml` from the GitHub repository.

### Variables

- `HTTP_PORT`: Listening HTTP port inside the container.
- `HTTPS_PORT`: Listening HTTPS port inside the container.
- `REDIRECT_TO_HTTPS`: Boolean value `true`/`false`. If set to `true`, it will redirect any HTTP traffic to HTTPS. Requires that `HTTPS_PORT` is set. Defaults to: `false`.
- `CERT_PATH`: Path inside the container for the user-specified PEM certificate file. Example: `'/path/to/cert'`. Note: single quotes are part of the value and mandatory!
- `KEY_PATH`: Path inside the container for the user-specified key file. Example

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
