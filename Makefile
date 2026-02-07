# Firefox Flash Kiosk - Makefile
# Common tasks for managing the container

.PHONY: help build up down restart logs shell status clean rebuild health

# Default target
help:
	@echo "Firefox Flash Kiosk - Available Commands:"
	@echo ""
	@echo "  make build       - Build the Docker image"
	@echo "  make up          - Start the container"
	@echo "  make down        - Stop the container"
	@echo "  make restart     - Restart the container"
	@echo "  make logs        - View container logs (follow mode)"
	@echo "  make shell       - Access container shell"
	@echo "  make status      - Show service status"
	@echo "  make clean       - Stop and remove container + volumes"
	@echo "  make rebuild     - Clean rebuild (no cache)"
	@echo "  make health      - Run health check"
	@echo ""

build:
	docker-compose build

up:
	docker-compose up -d
	@echo "Access: http://localhost:80"

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

shell:
	docker exec -it firefox-flash-kiosk /bin/bash

status:
	@docker-compose ps
	@docker exec firefox-flash-kiosk supervisorctl status 2>/dev/null || true

clean:
	docker-compose down -v
	rm -rf config/ config-*/

rebuild: clean
	docker-compose build --no-cache
	docker-compose up -d

health:
	@echo "=== Health Check ==="
	@docker-compose ps | grep -q "Up" && echo "✅ Container running" || echo "❌ Not running"
	@curl -s http://localhost:80 > /dev/null && echo "✅ Web accessible" || echo "❌ Web error"
	@docker exec firefox-flash-kiosk supervisorctl status 2>/dev/null || true
