@echo off
REM Script to build backend images using ktor buildImage and then run docker-compose

setlocal enabledelayedexpansion

echo Building main backend image using ktor buildImage...
cd Backend\main
call gradlew.bat :main:buildImage -x detekt --no-daemon
if %errorlevel% neq 0 (
    echo Error: Failed to build main backend image
    exit /b 1
)

echo Loading main backend image into Docker...
if exist "main\build\jib-image.tar" (
    docker load ^< main\build\jib-image.tar
    if %errorlevel% neq 0 (
        echo Warning: Failed to load main backend image
    ) else (
        echo Main backend image loaded successfully
    )
) else (
    echo Warning: jib-image.tar not found, trying to use existing image
)

cd ..\..

echo Building llm backend image using ktor buildImage...
cd Backend\main
call gradlew.bat :llm:buildImage -x detekt --no-daemon
if %errorlevel% neq 0 (
    echo Error: Failed to build llm backend image
    exit /b 1
)

echo Loading llm backend image into Docker...
if exist "llm\build\jib-image.tar" (
    docker load ^< llm\build\jib-image.tar
    if %errorlevel% neq 0 (
        echo Warning: Failed to load llm backend image
    ) else (
        echo LLM backend image loaded successfully
    )
) else (
    echo Warning: jib-image.tar not found, trying to use existing image
)

cd ..\..

echo Checking if images exist locally...
docker image inspect psychological-testing-main:latest >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: psychological-testing-main:latest image not found locally
    echo Please run the build steps above first
    exit /b 1
)

docker image inspect psychological-testing-llm:latest >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: psychological-testing-llm:latest image not found locally
    echo Please run the build steps above first
    exit /b 1
)

echo Starting all services with docker-compose...

REM Check if docker-compose or docker compose is available
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    docker-compose version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Error: docker-compose is not installed
        exit /b 1
    )
    docker-compose up -d %*
) else (
    docker compose up -d %*
)

endlocal

