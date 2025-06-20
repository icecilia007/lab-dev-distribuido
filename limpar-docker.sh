#!/bin/bash

echo "=== Docker Complete Cleanup Script ==="
echo "This script will remove ALL Docker containers, images, volumes, networks and cache"
echo "WARNING: This will delete EVERYTHING in Docker on this machine!"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "Starting complete Docker cleanup..."

echo ""
echo "1. Stopping all running containers..."
docker stop $(docker ps -aq) 2>/dev/null || echo "   No containers to stop"

echo ""
echo "2. Removing all containers..."
docker rm $(docker ps -aq) 2>/dev/null || echo "   No containers to remove"

echo ""
echo "3. Removing all images (including downloaded base images)..."
docker rmi $(docker images -aq) --force 2>/dev/null || echo "   No images to remove"

echo ""
echo "4. Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || echo "   No volumes to remove"

echo ""
echo "5. Removing all networks (except default ones)..."
docker network rm $(docker network ls -q) 2>/dev/null || echo "   No custom networks to remove"

echo ""
echo "6. Pruning Docker system (removing build cache, unused networks, etc.)..."
docker system prune -a --volumes --force

echo ""
echo "7. Removing Docker build cache..."
docker builder prune -a --force

echo ""
echo "8. Final verification - showing current Docker state:"
echo ""
echo "Containers:"
docker ps -a
echo ""
echo "Images:"
docker images
echo ""
echo "Volumes:"
docker volume ls
echo ""
echo "Networks:"
docker network ls
echo ""

echo "=== Docker cleanup completed! ==="
echo ""
echo "Your Docker environment is now completely clean."
echo "All images will be downloaded fresh when you run: docker compose up -d --build"
echo ""
echo "To test the system after cleanup:"
echo "1. Run: docker compose up -d --build"
echo "2. Wait for all services to start (about 2-3 minutes)"
echo "3. Run: ./test-sistema.sh"