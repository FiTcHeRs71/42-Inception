#!/bin/bash

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# Créer l'utilisateur FTP s'il n'existe pas
useradd -d /var/www/html -s /bin/bash $FTP_USER 2>/dev/null || true
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Créer le dossier sécurisé requis par vsftpd
mkdir -p /var/run/vsftpd/empty

# Lancer vsftpd en PID 1
exec /usr/sbin/vsftpd /etc/vsftpd.conf