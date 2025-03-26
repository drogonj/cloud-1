all: up

up:
	@echo "🚀 Lancement des conteneurs..."
	@docker compose up --build

down:
	@echo "🛑 Arrêt des conteneurs..."
	@docker compose down

clean: down
	@echo "🧹 Nettoyage des images Docker..."
	@docker image prune -af

fclean: clean
	@echo "🔥 Nettoyage complet..."
	@docker volume prune -af

.PHONY: all up down clean fclean init-certs