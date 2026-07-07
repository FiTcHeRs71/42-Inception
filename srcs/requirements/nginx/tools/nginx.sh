#!/bin/bash

# Créer le dossier pour le certificat
mkdir -p /etc/nginx/ssl

# Générer le certificat TLS auto-signé
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
	openssl req -x509 -nodes -newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=CH/ST=Vaud/L=Lausanne/O=42/CN=fducrot.42.fr"
fi

# Lancer nginx en PID 1
exec nginx -g "daemon off;"