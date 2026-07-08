# Developer documentation

This document describes how to set up, build and manage the Inception project as
a developer.

## Setting up the environment from scratch

### Prerequisites

- A virtual machine (developed on Ubuntu).
- Docker and the Docker Compose plugin installed.
- The domain name resolving to localhost. Add this line to `/etc/hosts`:

  ```
  127.0.0.1    fducrot.42.fr
  ```

### Configuration files (not tracked by git)

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

  # FTP
  FTP_USER=fducrot
  ```

- The `secrets/` folder, one password per file (no trailing newline — use
  `echo -n`):

  ```bash
  echo -n 'db_user_password'   > secrets/db_password.txt
  echo -n 'db_root_password'   > secrets/db_root_password.txt
  echo -n 'wp_admin_password'  > secrets/credentials.txt
  echo -n 'wp_user_password'   > secrets/visitor.txt
  echo -n 'ftp_password'       > secrets/ftp_password.txt
  ```

  These files and `srcs/.env` are in `.gitignore` and must never be committed.

## Building and launching the project

The `Makefile` at the root drives Docker Compose:

```bash
make          # create data directories, build images and start the stack
make down     # stop the containers
make clean    # stop the containers and remove the Docker volumes
make fclean   # clean + remove persistent data on the host
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
├── README.md, USER_DOC.md, DEV_DOC.md
├── secrets/                 (ignored by git)
└── srcs/
    ├── .env                 (ignored by git)
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/    (Dockerfile, conf/, tools/)
        ├── nginx/      (Dockerfile, conf/, tools/)
        ├── wordpress/  (Dockerfile, conf/, tools/)
        └── bonus/
            ├── adminer/
            ├── redis/
            ├── static/
            ├── ftp/
            └── glances/
```

Each service is built from `debian:bookworm`. The entrypoint of each service
performs first-time initialisation if needed, then launches its daemon as PID 1
with `exec`.

## Services and ports

| Service     | Internal port | Published to host | Role                          |
|-------------|---------------|-------------------|-------------------------------|
| MariaDB     | 3306          | No                | Database                      |
| WordPress   | 9000          | No                | php-fpm (FastCGI)             |
| NGINX       | 443           | 443               | HTTPS entry point             |
| Redis       | 6379          | No                | WordPress object cache        |
| Adminer     | 8080          | 8080              | DB admin web UI               |
| Static site | 8081          | 8081              | Static website                |
| FTP         | 21 / 21000-21010 | same           | File access to WordPress vol. |
| Glances     | 61208         | 61208             | Monitoring dashboard          |

## Managing containers and volumes

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

# Inspect a container
docker inspect nginx

# Rebuild a single service
docker compose -f srcs/docker-compose.yml up --build -d mariadb
```

## Where the data is stored and how it persists

The two persistent stores are named volumes bound to a fixed location on the
host:

- `db_data`  -> `/home/fducrot/data/mariadb`  (MariaDB database files)
- `wp_data`  -> `/home/fducrot/data/wordpress` (WordPress files; also mounted by
  NGINX and the FTP service so they share the same files)

Because the data lives under `/home/fducrot/data`, it survives `make down` and
`make clean`, and is removed only by `make fclean`.

Communication between services goes through the `inception` Docker network,
where each service is reachable by its name. Only the services that need a
browser or client (NGINX, Adminer, static site, FTP, Glances) publish a port to
the host; MariaDB, WordPress and Redis stay internal.
