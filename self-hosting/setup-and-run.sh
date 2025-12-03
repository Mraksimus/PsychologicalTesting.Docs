#!/bin/bash

# Script to clone repositories, build backend images using ktor buildImage, and run docker-compose
# Usage: ./setup-and-run.sh [BACKEND_REPO_URL] [FRONTEND_REPO_URL]

set -e

# Default repository URLs (can be overridden via command line arguments)
BACKEND_REPO_URL="${1:-https://github.com/mraksimus/psychologicaltesting.backend.git}"
FRONTEND_REPO_URL="${2:-https://github.com/mraksimus/psychologicaltesting.frontend.git}"

echo "=========================================="
echo "Psychological Testing - Setup and Run"
echo "=========================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git first."
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed. Please install docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

# Clone Backend repository if it doesn't exist
if [ ! -d "Backend/main" ]; then
    echo "Cloning Backend repository..."
    mkdir -p Backend
    git clone "$BACKEND_REPO_URL" Backend/main
    echo "Backend repository cloned successfully"
else
    echo "Backend repository already exists, skipping clone"
    echo "To update, run: cd Backend/main && git pull"
fi

# Clone Frontend repository if it doesn't exist
if [ ! -d "Frontend/PsychologicalTesting" ]; then
    echo "Cloning Frontend repository..."
    mkdir -p Frontend
    git clone "$FRONTEND_REPO_URL" Frontend/PsychologicalTesting
    echo "Frontend repository cloned successfully"
else
    echo "Frontend repository already exists, skipping clone"
    echo "To update, run: cd Frontend/PsychologicalTesting && git pull"
fi

echo ""
echo "=========================================="
echo "Building backend images..."
echo "=========================================="
echo ""

# Build main backend image
echo "Building main backend image using ktor buildImage..."
cd Backend/main
./gradlew :main:buildImage -x detekt --no-daemon

echo "Loading main backend image into Docker..."
if [ -f main/build/jib-image.tar ]; then
    docker load < main/build/jib-image.tar
    echo "Main backend image loaded successfully"
else
    echo "Warning: jib-image.tar not found, trying to use existing image"
fi

# Build llm backend image
echo "Building llm backend image using ktor buildImage..."
./gradlew :llm:buildImage -x detekt --no-daemon

echo "Loading llm backend image into Docker..."
if [ -f llm/build/jib-image.tar ]; then
    docker load < llm/build/jib-image.tar
    echo "LLM backend image loaded successfully"
else
    echo "Warning: jib-image.tar not found, trying to use existing image"
fi

cd ../..

# Verify images are loaded
echo ""
echo "Verifying images are loaded..."
if ! docker image inspect psychological-testing-main:latest >/dev/null 2>&1; then
    echo "Error: psychological-testing-main:latest image not found in Docker"
    echo "Please check if the image was loaded successfully"
    exit 1
fi

if ! docker image inspect psychological-testing-llm:latest >/dev/null 2>&1; then
    echo "Error: psychological-testing-llm:latest image not found in Docker"
    echo "Please check if the image was loaded successfully"
    exit 1
fi

echo "All images verified successfully"
echo ""
echo "=========================================="
echo "Starting all services with docker-compose..."
echo "=========================================="
echo ""

# Start docker-compose
# Use -d flag to run in background, or pass it as argument: ./setup-and-run.sh -d
if [[ "$*" == *"-d"* ]] || [[ "$*" == *"--detach"* ]]; then
    docker-compose up "$@"
else
    echo "Starting in foreground. Use -d flag to run in background."
    docker-compose up "$@"
fi

