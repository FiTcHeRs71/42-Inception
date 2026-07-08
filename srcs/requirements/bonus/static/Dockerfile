FROM debian:bookworm

RUN apt update && apt install -y python3 && apt clean

RUN mkdir -p /var/www/static
COPY site/subset_sum_visualizer.html /var/www/static/index.html

EXPOSE 8081

ENTRYPOINT ["python3", "-m", "http.server", "8081", "--directory", "/var/www/static"]