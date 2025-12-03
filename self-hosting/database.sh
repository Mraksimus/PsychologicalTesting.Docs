#!/bin/bash

# Script to seed the database with test and question data
# Usage: ./seed-database.sh [SQL_FILE]

set -e

# Default SQL file
SQL_FILE="${1:-seed-database.sql}"

echo "=========================================="
echo "Seeding database with test data"
echo "=========================================="
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

# Check if SQL file exists
if [ ! -f "$SQL_FILE" ]; then
    echo "Error: SQL file '$SQL_FILE' not found"
    echo "Usage: ./seed-database.sh [SQL_FILE]"
    exit 1
fi

# Check if PostgreSQL container is running
if ! docker-compose ps psql | grep -q "Up"; then
    echo "Error: PostgreSQL container is not running"
    echo "Please start the services first: docker-compose up -d"
    exit 1
fi

echo "Loading SQL file: $SQL_FILE"
echo ""

# Execute SQL file in PostgreSQL container
docker-compose exec -T psql psql -U postgres -d postgres < "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Database seeded successfully!"
    echo "=========================================="
else
    echo ""
    echo "Error: Failed to seed database"
    exit 1
fi

