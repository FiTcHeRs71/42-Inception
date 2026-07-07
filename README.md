*This project has been created as part of the 42 curriculum by fducrot.*

# Inception

## Description

Inception is a system administration project whose goal is to set up a small
web infrastructure composed of several services, each running in its own Docker
container, and orchestrated with Docker Compose inside a virtual machine.

The infrastructure serves a WordPress website over HTTPS and is made of three
services:

- **MariaDB** — the database server that stores the WordPress data.
- **WordPress + php-fpm** — the CMS and the PHP engine that executes it.
- **NGINX** — the web server, and the single entry point of the whole
  infrastructure, reachable only over TLS on port 443.

Each image is built from `debian:bookworm` (the penultimate stable Debian
release). No ready-made application image is pulled: every service is built from
its own Dockerfile. The containers communicate through a dedicated Docker
network, persistent data is stored in named volumes, and all sensitive
credentials are handled through Docker secrets.

## Instructions

### Prerequisites

- A virtual machine (this project was developed on Ubuntu).
- Docker and the Docker Compose plugin installed.
- The domain name `fducrot.42.fr` pointing to `127.0.0.1` in `/etc/hosts`:

  ```
  127.0.0.1    fducrot.42.fr
  ```

- A `srcs/.env` file and the `secrets/` files must be present (they are not
  tracked by git — see DEV_DOC.md).

### Build and run

From the root of the repository:

```bash
make          # build the images and start the whole stack
```

Other targets:

```bash
make down     # stop the containers
make clean    # stop the containers and remove the volumes
make fclean   # clean + remove the persistent data on the host
make re       # full rebuild from scratch
```

### Access

Once the stack is running, open:

```
https://fducrot.42.fr
```

The browser will warn about the certificate because it is self-signed; this is
expected. The WordPress administration panel is available at
`https://fducrot.42.fr/wp-admin`.

## Project description

### Use of Docker and structure of the sources

All the configuration lives in the `srcs/` folder. Each service has its own
folder under `srcs/requirements/`, containing its `Dockerfile`, its
configuration files (`conf/`) and its entrypoint script (`tools/`). The
`docker-compose.yml` file describes the three services, the network, the two
named volumes and the secrets. A `Makefile` at the root builds and launches
everything.

The main design choices are:

- **One process per container.** Each service runs a single daemon as PID 1
  (`mariadbd`, `php-fpm`, `nginx`), started with `exec` from the entrypoint
  script so that the daemon truly becomes PID 1. No `tail -f`, `sleep infinity`
  or similar hack is used. A container lives as long as its main process lives,
  which also makes the `restart` policy meaningful.
- **Initialisation is idempotent.** Each entrypoint detects whether the service
  has already been initialised (for example by checking whether the database
  directory already exists) and only performs the first-time setup when needed,
  so restarts do not re-initialise or crash the service.
- **NGINX is the only entry point.** It listens on port 443 with TLSv1.2 or
  TLSv1.3 only, and forwards PHP requests to the WordPress container on port
  9000 through FastCGI.

### Virtual Machines vs Docker

A **virtual machine** emulates a full machine: it runs its own kernel and a
complete operating system on top of a hypervisor. It is strongly isolated but
heavy, slow to boot and resource-hungry.

**Docker** uses containers, which share the host kernel and only package the
application and its dependencies. Containers are lightweight, start almost
instantly and are far more efficient in terms of CPU, memory and disk. The
trade-off is weaker isolation than a VM (same kernel). In this project Docker is
the right tool because we run several small, independent services that must be
reproducible and cheap to rebuild — a VM per service would be wasteful.

### Secrets vs Environment Variables

**Environment variables** (here, the `.env` file) are convenient for
non-sensitive configuration such as the domain name, the database name or the
user name. Their weakness is exposure: they are injected into the container's
environment and can be read by anyone able to run `docker inspect` or
`docker exec ... env`, and a mishandled `.env` file can end up in a git
repository.

**Docker secrets** are meant for confidential data (passwords, keys). Their
content is stored in files that are mounted read-only inside `/run/secrets/`,
only in the containers that explicitly need them, and they never appear in the
container's environment or in `docker inspect`. In this project the database
passwords and the WordPress credentials are handled as secrets, while only
non-sensitive values live in `.env`.

### Docker Network vs Host Network

With the **host network**, a container shares the host's network stack
directly: no isolation, and port conflicts with the host become possible. The
subject forbids this mode.

A **Docker (bridge) network** creates an isolated virtual network for the
containers. On it, each container is reachable by its service name (for example
`mariadb` or `wordpress`), which acts as an internal DNS name. This provides
isolation and clean service-to-service communication without exposing the
services to the outside world. In this project only NGINX publishes a port to
the host (`443:443`); MariaDB and WordPress are reachable only from inside the
network, which reduces the attack surface.

### Docker Volumes vs Bind Mounts

A **bind mount** maps an arbitrary host directory directly into a container.
It is simple but tightly coupled to the host's filesystem layout and is not
managed by Docker as a first-class object.

A **named volume** is a storage object managed by Docker, with its own life
cycle (it appears in `docker volume ls`). The subject requires named volumes for
the two persistent stores (the WordPress database and the WordPress files),
while also requiring their data to live under `/home/fducrot/data`. This project
therefore declares named volumes whose underlying storage is bound to
`/home/fducrot/data/mariadb` and `/home/fducrot/data/wordpress`: they remain
managed named volumes, but their data is stored at the required location.

## Resources

Classic references used to understand and build this project:

- Docker documentation — Dockerfile reference, Compose file reference, secrets,
  volumes and networking.
- MariaDB documentation — server initialisation (`mariadb-install-db`),
  `--init-file`, user management and the `bind-address` setting.
- WordPress and WP-CLI documentation — `wp core download`, `wp config create`,
  `wp core install`, `wp user create`.
- NGINX documentation — TLS configuration (`ssl_protocols`, certificates) and
  FastCGI (`fastcgi_pass`) to communicate with php-fpm.
- OpenSSL documentation — generating a self-signed certificate.

### Use of AI

AI was used as a learning and reviewing aid, not as a code generator to copy
blindly. Concretely, it helped with:

- explaining concepts before implementation (PID 1 and the role of `exec`, the
  difference between a database client and its daemon, the FastCGI flow between
  NGINX and php-fpm, TLS and self-signed certificates, Docker secrets vs
  environment variables);
- reviewing and debugging configuration and scripts iteratively (for example the
  MariaDB socket directory, the `bind-address` setting, the php-fpm listen port,
  and the entrypoint restart behaviour);
