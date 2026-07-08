FROM debian:bookworm

RUN apt update && apt install -y vsftpd && apt clean

COPY "conf/vsftpd.conf" "/etc/vsftpd.conf"
COPY "tools/ftp.sh" "/usr/local/bin/ftp.sh"

RUN chmod +x "/usr/local/bin/ftp.sh"

EXPOSE 21

ENTRYPOINT [ "/usr/local/bin/ftp.sh" ]