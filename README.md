*This project has been created as part of the 42 curriculum by fducrot.*

# Inception

## Description

Inception is a system administration project whose goal is to set up a small
web infrastructure composed of several services, each running in its own Docker
container, and orchestrated with Docker Compose inside a virtual machine.

The mandatory infrastructure serves a WordPress website over HTTPS and is made
of three services:

- **MariaDB** — the database server that stores the WordPress data.
- **WordPress + php-fpm** — the CMS and the PHP engine that executes it.
- **NGINX** — the web server, and the single entry point of the mandatory
  infrastructure, reachable only over TLS on port 443.

Five bonus services extend the stack: Adminer, Redis cache, a static website,
an FTP server and a Glances monitoring dashboard.

Each image is built from `debian:bookworm` (the penultimate stable Debian
release). No ready-made application image is pulled: every service is built from
its own Dockerfile. The containers communicate through a dedicated Docker
network, persistent data is stored in named volumes, and all sensitive
credentials are handled through Docker secrets.

## Services overview

Each service, in one or two lines:

- **MariaDB** — the relational database. Stores all WordPress content (posts,
  users, settings). Runs `mariadbd` as PID 1, reachable only on the internal
  network.
- **WordPress + php-fpm** — the website itself. php-fpm executes the WordPress
  PHP code and connects to MariaDB. Exposes port 9000 for NGINX.
- **NGINX** — the reverse entry point. Serves the site over HTTPS (TLSv1.2/1.3)
  and forwards PHP requests to WordPress via FastCGI. The only mandatory service
  published to the host.
- **Adminer** *(bonus)* — a lightweight web interface to administer the MariaDB
  database from the browser.
- **Redis** *(bonus)* — an in-memory cache used by WordPress as an object cache,
  to speed up pages and reduce database load.
- **Static site** *(bonus)* — a small non-PHP HTML/CSS/JS website served by
  Python's built-in HTTP server.
- **FTP** *(bonus)* — a vsftpd server pointing to the WordPress files volume,
  allowing file access over FTP.
- **Glances** *(bonus)* — a system-monitoring dashboard exposing CPU, memory,
  network and process metrics in the browser.

## Ports

| Port          | Service     | Exposed to host | Purpose                                   |
|---------------|-------------|-----------------|-------------------------------------------|
| 443           | NGINX       | Yes             | HTTPS entry point (TLSv1.2/1.3)           |
| 3306          | MariaDB     | No (internal)   | Database connections                      |
| 9000          | WordPress   | No (internal)   | php-fpm (FastCGI from NGINX)              |
| 6379          | Redis       | No (internal)   | Cache connections from WordPress          |
| 8080          | Adminer     | Yes             | Database admin web interface              |
| 8081          | Static site | Yes             | Static website                            |
| 21            | FTP         | Yes             | FTP command channel                       |
| 21000-21010   | FTP         | Yes             | FTP passive-mode data channel             |
| 61208         | Glances     | Yes             | Monitoring dashboard                      |

Only NGINX and the bonus services that need a browser or client are published to
the host. MariaDB, WordPress and Redis stay on the internal network and are
reachable only by their service name.

## Instructions

### Prerequisites

- A virtual machine (developed on Ubuntu).
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
make down     # stop the containers
make clean    # stop the containers and remove the volumes
make fclean   # clean + remove the persistent data on the host
make re       # full rebuild from scratch
```

### Access

- Website: `https://fducrot.42.fr`
- WordPress admin: `https://fducrot.42.fr/wp-admin`
- Adminer: `http://<host>:8080`
- Static site: `http://<host>:8081`
- Glances: `http://<host>:61208`
- FTP: `ftp://<host>:21`

The browser will warn about the self-signed TLS certificate; this is expected.

## Project description

### Use of Docker and structure of the sources

All the configuration lives in the `srcs/` folder. Each service has its own
folder under `srcs/requirements/` (bonus services under
`srcs/requirements/bonus/`), containing its `Dockerfile`, its configuration
files (`conf/`) and its entrypoint script (`tools/`). The `docker-compose.yml`
file describes the services, the network, the named volumes and the secrets. A
`Makefile` at the root builds and launches everything.

The main design choices are:

- **One process per container.** Each service runs a single daemon as PID 1,
  started with `exec` from the entrypoint script so that the daemon truly
  becomes PID 1. No `tail -f`, `sleep infinity` or similar hack is used.
- **Idempotent initialisation.** Each entrypoint detects whether the service has
  already been initialised and only performs the first-time setup when needed,
  so restarts do not re-initialise or crash the service.
- **NGINX is the only mandatory entry point.** It listens on port 443 with
  TLSv1.2 or TLSv1.3 only, and forwards PHP requests to WordPress on port 9000
  through FastCGI.

### Virtual Machines vs Docker

A **virtual machine** emulates a full machine: it runs its own kernel and a
complete operating system on top of a hypervisor. It is strongly isolated but
heavy, slow to boot and resource-hungry.

**Docker** uses containers, which share the host kernel and only package the
application and its dependencies. Containers are lightweight, start almost
instantly and are far more efficient. The trade-off is weaker isolation than a
VM. In this project Docker is the right tool because we run several small,
independent services that must be reproducible and cheap to rebuild.

### Secrets vs Environment Variables

**Environment variables** (the `.env` file) are convenient for non-sensitive
configuration such as the domain name, the database name or user names. Their
weakness is exposure: they are injected into the container environment and can
be read with `docker inspect` or `docker exec ... env`.

**Docker secrets** are meant for confidential data. Their content is mounted
read-only inside `/run/secrets/`, only in the containers that need them, and
they never appear in the environment or in `docker inspect`. In this project the
database passwords, the WordPress credentials and the FTP password are handled
as secrets, while only non-sensitive values live in `.env`.

### Docker Network vs Host Network

With the **host network**, a container shares the host's network stack
directly: no isolation, and port conflicts become possible. The subject forbids
this mode.

A **Docker (bridge) network** creates an isolated virtual network. On it, each
container is reachable by its service name (for example `mariadb` or
`wordpress`), which acts as internal DNS. Only the services that need to be
reached from outside publish a port; the rest stay internal, which reduces the
attack surface.

### Docker Volumes vs Bind Mounts

A **bind mount** maps an arbitrary host directory directly into a container:
simple, but tightly coupled to the host layout and not managed by Docker.

A **named volume** is a storage object managed by Docker, with its own life
cycle. The subject requires named volumes for the two persistent stores, while
also requiring their data to live under `/home/fducrot/data`. This project
declares named volumes whose underlying storage is bound to
`/home/fducrot/data/mariadb` and `/home/fducrot/data/wordpress`: they remain
managed named volumes, but their data is stored at the required location.

## Resources

- Docker documentation — Dockerfile, Compose, secrets, volumes, networking.
- MariaDB documentation — initialisation, `--init-file`, `bind-address`.
- WordPress and WP-CLI documentation — download, config, install, users.
- NGINX documentation — TLS configuration and FastCGI.
- OpenSSL documentation — self-signed certificate generation.
- Redis / redis-cache plugin, vsftpd and Glances documentation for the bonus
  services.

### Use of AI

AI was used as a learning and reviewing aid, not as a code generator to copy
blindly. It helped with explaining concepts before implementation (PID 1 and
`exec`, the FastCGI flow, TLS, Docker secrets, FTP passive mode, container
isolation for monitoring), with reviewing and debugging scripts and
configuration iteratively, and with drafting this documentation from the actual
state of the project. Every file was written, tested and understood by the
author, so that each line can be explained during the evaluation.
