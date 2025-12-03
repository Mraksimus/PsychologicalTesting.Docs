#!/bin/bash

# Script to build backend images using ktor buildImage and then run docker-compose

set -e

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

cd ../..

echo "Building llm backend image using ktor buildImage..."
cd Backend/main
./gradlew :llm:buildImage -x detekt --no-daemon

echo "Loading llm backend image into Docker..."
if [ -f llm/build/jib-image.tar ]; then
    docker load < llm/build/jib-image.tar
    echo "LLM backend image loaded successfully"
else
    echo "Warning: jib-image.tar not found, trying to use existing image"
fi

cd ../..

echo "Checking if images exist locally..."
if ! docker image inspect psychological-testing-main:latest >/dev/null 2>&1; then
    echo "Error: psychological-testing-main:latest image not found locally"
    echo "Please run the build steps above first"
    exit 1
fi

if ! docker image inspect psychological-testing-llm:latest >/dev/null 2>&1; then
    echo "Error: psychological-testing-llm:latest image not found locally"
    echo "Please run the build steps above first"
    exit 1
fi

echo "Starting all services with docker-compose..."
docker-compose up -d "$@"

