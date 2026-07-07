COMPOSE = docker compose -f srcs/docker-compose.yml

up:
	mkdir -p /home/fducrot/data/mariadb /home/fducrot/data/wordpress
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean: clean
	sudo rm -rf /home/fducrot/data/mariadb/* /home/fducrot/data/wordpress/*

re: fclean up

.PHONY: up down clean re