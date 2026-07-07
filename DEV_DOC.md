# Developer documentation

This document describes how to set up, build and manage the Inception project
as a developer.

## Setting up the environment from scratch

### Prerequisites

- A virtual machine (developed on Ubuntu).
- Docker and the Docker Compose plugin installed.
- The domain name resolving to localhost. Add this line to `/etc/hosts`:

  ```
  127.0.0.1    fducrot.42.fr
  ```

### Configuration files

The following files are required but **not** tracked by git, so they must be
created before the first build.

- `srcs/.env` — non-sensitive environment variables:

  ```
  DOMAIN_NAME=fducrot.42.fr

  # MariaDB
  MYSQL_DATABASE=wordpress
  MYSQL_USER=fducrot

  # WordPress
  WP_ADMIN_USER=fducrot
  WP_ADMIN_EMAIL=fducrot@student.42lausanne.ch
  WP_USER=visitor
  WP_USER_EMAIL=visitor@student.42.fr
  ```

- The `secrets/` folder, with one password per file (no trailing newline —
  create them with `echo -n`):

  ```bash
  echo -n 'your_db_user_password'   > secrets/db_password.txt
  echo -n 'your_db_root_password'   > secrets/db_root_password.txt
  echo -n 'your_wp_admin_password'  > secrets/credentials.txt
  echo -n 'your_wp_user_password'   > secrets/visitor.txt
  ```

  These files, and `srcs/.env`, are listed in `.gitignore` and must never be
  committed.

## Building and launching the project

The `Makefile` at the root drives Docker Compose. From the repository root:

```bash
make          # create the data directories, build the images and start the stack
make down     # stop the containers
make clean    # stop the containers and remove the Docker volumes
make fclean   # clean + remove the persistent data on the host
make re       # full rebuild from a clean state
```

Under the hood, `make` runs:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

## Project structure

```
inception/
├── Makefile
├── secrets/                 (ignored by git)
└── srcs/
    ├── .env                 (ignored by git)
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/    (Dockerfile, conf/, tools/)
        ├── nginx/      (Dockerfile, conf/, tools/)
        └── wordpress/  (Dockerfile, conf/, tools/)
```

Each service is built from `debian:bookworm`. The entrypoint script of each
service performs its first-time initialisation if needed, then launches the
daemon as PID 1 with `exec`.

## Managing containers and volumes

Useful commands (run from the repository root):

```bash
# List running containers
docker ps

# Follow the logs of a service
docker compose -f srcs/docker-compose.yml logs -f mariadb

# Open a shell inside a container
docker exec -it wordpress bash

# List volumes and networks
docker volume ls
docker network ls

# Inspect a container (config, mounts, network)
docker inspect nginx
```

To rebuild a single service after a change:

```bash
docker compose -f srcs/docker-compose.yml up --build -d mariadb
```

## Where the data is stored and how it persists

The two persistent stores are **named volumes** whose data is bound to a fixed
location on the host, as required by the subject:

- `db_data`  → `/home/fducrot/data/mariadb`  (MariaDB database files)
- `wp_data`  → `/home/fducrot/data/wordpress` (WordPress website files)

Because the data lives on the host under `/home/fducrot/data`, it survives
`make down` and `make clean` (which only remove containers and Docker-managed
volume metadata). It is removed only by `make fclean`, which explicitly deletes
the contents of those directories.

Communication between services goes through the `inception` Docker network,
where each service is reachable by its name (`mariadb`, `wordpress`, `nginx`).
Only NGINX publishes a port to the host (`443:443`); MariaDB and WordPress are
reachable only from inside the network.
