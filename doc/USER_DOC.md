# User documentation

This document explains, in simple terms, how to use the Inception stack as an
end user or administrator.

## Services provided by the stack

The infrastructure runs three services, each in its own container:

- **NGINX** — the web server and the single entry point. It serves the website
  over HTTPS (port 443, TLSv1.2/TLSv1.3 only).
- **WordPress + php-fpm** — the website itself (a WordPress CMS) and the PHP
  engine that runs it.
- **MariaDB** — the database that stores all the WordPress content (posts,
  users, settings).

Together they serve a WordPress website reachable at `https://fducrot.42.fr`.

## Starting and stopping the project

All commands are run from the root of the repository.

- **Start** the whole stack:

  ```bash
  make
  ```

- **Stop** the containers:

  ```bash
  make down
  ```

- **Restart** from a clean state (rebuild everything):

  ```bash
  make re
  ```

## Accessing the website and the administration panel

- **Website:** open `https://fducrot.42.fr` in a browser.

  The browser will display a security warning because the TLS certificate is
  self-signed. This is expected: choose "Advanced" then "Continue" to reach the
  site.

- **Administration panel:** open `https://fducrot.42.fr/wp-admin` and log in
  with the administrator account.

## Locating and managing credentials

Sensitive credentials are **not** stored in plain text in the repository. They
are handled in two ways:

- **Non-sensitive values** (domain name, database name, user names, e-mails) are
  stored in `srcs/.env`.
- **Passwords** (database user, database root, WordPress administrator, second
  WordPress user) are stored as **Docker secrets**, in the `secrets/` folder:

  - `secrets/db_password.txt` — WordPress database user password
  - `secrets/db_root_password.txt` — MariaDB root password
  - `secrets/credentials.txt` — WordPress administrator password
  - `secrets/visitor.txt` — second WordPress user password

Both `srcs/.env` and `secrets/` are ignored by git, so no password is ever
published in the repository. To change a credential, edit the corresponding
file and rebuild the stack with `make re`.

The two WordPress accounts are:

- an **administrator** account (username `fducrot`),
- a second **author** account (username `visitor`).

## Checking that the services are running correctly

- **List the running containers:**

  ```bash
  docker ps
  ```

  You should see `nginx`, `wordpress` and `mariadb`, all with the status `Up`.

- **Check the website responds over HTTPS:**

  ```bash
  curl -k https://fducrot.42.fr
  ```

  This should return the HTML of the WordPress home page (look for
  `<title>Inception</title>`).

- **Read a service's logs** (for troubleshooting):

  ```bash
  docker compose -f srcs/docker-compose.yml logs mariadb
  docker compose -f srcs/docker-compose.yml logs wordpress
  docker compose -f srcs/docker-compose.yml logs nginx
  ```
