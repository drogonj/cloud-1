all: help

help:
	@echo "Usage:"
	@echo "make up		-> start containers in detach mode"
	@echo "make down	-> down containers"
	@echo "make clean	-> 'make down' && clean images"
	@echo "make fclean	-> 'make clean' && clean volumes"
	@echo "make logs	-> display logs"

up:
	@echo "🚀 Launch..."
	@docker compose up --build -d

down:
	@echo "🛑 Stopping containers..."
	@docker compose down

clean: down
	@echo "🧹 Cleaning docker images..."
	@docker image prune -af

fclean: clean
	@echo "🔥 Cleaning volumes..."
	@docker volume prune -af

logs:
	@docker compose logs -f

.PHONY: all up down clean fclean logs