# User documentation

This document explains, in simple terms, how to use the Inception stack as an
end user or administrator.

## Services provided by the stack

The infrastructure runs eight containers, each in its own service.

Mandatory services:

- **NGINX** — the web server and the single mandatory entry point. Serves the
  website over HTTPS (port 443, TLSv1.2/1.3 only).
- **WordPress + php-fpm** — the website itself (a WordPress CMS) and the PHP
  engine that runs it.
- **MariaDB** — the database that stores all the WordPress content.

Bonus services:

- **Adminer** — a web interface to view and manage the database.
- **Redis** — an in-memory cache that speeds up WordPress.
- **Static site** — a small standalone HTML/CSS/JS website.
- **FTP** — a file-transfer server giving access to the WordPress files.
- **Glances** — a monitoring dashboard for system resources.

## Ports and where each service lives

| Address                         | Service     | What you see                         |
|---------------------------------|-------------|--------------------------------------|
| https://fducrot.42.fr           | NGINX + WP  | The WordPress website (HTTPS)        |
| https://fducrot.42.fr/wp-admin  | WordPress   | The administration panel             |
| http://<host>:8080              | Adminer     | The database admin interface         |
| http://<host>:8081              | Static site | The standalone static website        |
| http://<host>:61208             | Glances     | The monitoring dashboard             |
| ftp://<host>:21                 | FTP         | The WordPress files over FTP         |

MariaDB (3306), WordPress/php-fpm (9000) and Redis (6379) have no public
address: they are used internally by the other services.

## Starting and stopping the project

All commands are run from the root of the repository.

- **Start** the whole stack: `make`
- **Stop** the containers: `make down`
- **Restart** from a clean state (rebuild everything): `make re`

## Accessing the website and the administration panel

- **Website:** open `https://fducrot.42.fr` in a browser. The browser will
  display a security warning because the TLS certificate is self-signed; choose
  "Advanced" then "Continue".
- **Administration panel:** open `https://fducrot.42.fr/wp-admin` and log in with
  the administrator account.

## Locating and managing credentials

Credentials are not stored in plain text in the repository:

- **Non-sensitive values** (domain, database name, user names, e-mails) are in
  `srcs/.env`.
- **Passwords** are stored as Docker secrets in the `secrets/` folder:
  - `db_password.txt` — WordPress database user password
  - `db_root_password.txt` — MariaDB root password
  - `credentials.txt` — WordPress administrator password
  - `visitor.txt` — second WordPress user password
  - `ftp_password.txt` — FTP user password

Both `srcs/.env` and `secrets/` are ignored by git. To change a credential, edit
the corresponding file and rebuild with `make re`.

The two WordPress accounts are an **administrator** (username `fducrot`) and a
second **author** account (username `visitor`).

## Checking that the services are running correctly

- **List the running containers:** `docker ps` — you should see the eight
  containers with the status `Up`.
- **Check the website responds:** `curl -k https://fducrot.42.fr` should return
  the WordPress home page HTML.
- **Read a service's logs:**
  `docker compose -f srcs/docker-compose.yml logs <service>`
  (for example `mariadb`, `wordpress`, `nginx`, `redis`, `ftp`, `glances`).
