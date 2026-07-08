FROM debian:bookworm

RUN apt update && apt install -y python3 python3-pip && apt clean
RUN pip install --break-system-packages "glances[web]"

COPY "tools/glances.sh" "/usr/local/bin"

RUN chmod +x "/usr/local/bin/glances.sh"

EXPOSE 61208

ENTRYPOINT [ "/usr/local/bin/glances.sh" ]