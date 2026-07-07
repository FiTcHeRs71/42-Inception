FROM debian:bookworm

RUN apt update && apt install -y python3 && apt clean

COPY "site/subset_sum_visualizer.html" "/var/www/static"

EXPOSE 8081

RUN exec