@echo off
REM Script to clone repositories, build backend images using ktor buildImage, and run docker-compose
REM Usage: setup-and-run.bat [BACKEND_REPO_URL] [FRONTEND_REPO_URL]

setlocal enabledelayedexpansion

REM Default repository URLs (can be overridden via command line arguments)
if "%~1"=="" (
    set BACKEND_REPO_URL=https://github.com/mraksimus/psychologicaltesting.backend.git
) else (
    set BACKEND_REPO_URL=%~1
)

if "%~2"=="" (
    set FRONTEND_REPO_URL=https://github.com/mraksimus/psychologicaltesting.frontend.git
) else (
    set FRONTEND_REPO_URL=%~2
)

echo ==========================================
echo Psychological Testing - Setup and Run
echo ==========================================
echo.

REM Check if git is installed
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: git is not installed. Please install git first.
    exit /b 1
)

REM Check if docker is installed
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: docker is not installed. Please install docker first.
    exit /b 1
)

REM Check if docker-compose is installed
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    docker-compose version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Error: docker-compose is not installed. Please install docker-compose first.
        exit /b 1
    )
    set DOCKER_COMPOSE_CMD=docker-compose
) else (
    set DOCKER_COMPOSE_CMD=docker compose
)

REM Clone Backend repository if it doesn't exist
if not exist "Backend\main" (
    echo Cloning Backend repository...
    if not exist "Backend" mkdir Backend
    git clone "%BACKEND_REPO_URL%" Backend\main
    if %errorlevel% neq 0 (
        echo Error: Failed to clone Backend repository
        exit /b 1
    )
    echo Backend repository cloned successfully
) else (
    echo Backend repository already exists, skipping clone
    echo To update, run: cd Backend\main ^&^& git pull
)

REM Clone Frontend repository if it doesn't exist
if not exist "Frontend\PsychologicalTesting" (
    echo Cloning Frontend repository...
    if not exist "Frontend" mkdir Frontend
    git clone "%FRONTEND_REPO_URL%" Frontend\PsychologicalTesting
    if %errorlevel% neq 0 (
        echo Error: Failed to clone Frontend repository
        exit /b 1
    )
    echo Frontend repository cloned successfully
) else (
    echo Frontend repository already exists, skipping clone
    echo To update, run: cd Frontend\PsychologicalTesting ^&^& git pull
)

echo.
echo ==========================================
echo Building backend images...
echo ==========================================
echo.

REM Build main backend image
echo Building main backend image using ktor buildImage...
cd Backend\main
call gradlew.bat :main:buildImage -x detekt --no-daemon
if %errorlevel% neq 0 (
    echo Error: Failed to build main backend image
    exit /b 1
)

echo Loading main backend image into Docker...
if exist "main\build\jib-image.tar" (
    docker load -i main\build\jib-image.tar
    if %errorlevel% neq 0 (
        echo Warning: Failed to load main backend image
    ) else (
        echo Main backend image loaded successfully
    )
) else (
    echo Warning: jib-image.tar not found, trying to use existing image
)

REM Build llm backend image
echo Building llm backend image using ktor buildImage...
call gradlew.bat :llm:buildImage -x detekt --no-daemon
if %errorlevel% neq 0 (
    echo Error: Failed to build llm backend image
    exit /b 1
)

echo Loading llm backend image into Docker...
if exist "llm\build\jib-image.tar" (
    docker load -i llm\build\jib-image.tar
    if %errorlevel% neq 0 (
        echo Warning: Failed to load llm backend image
    ) else (
        echo LLM backend image loaded successfully
    )
) else (
    echo Warning: jib-image.tar not found, trying to use existing image
)

cd ..\..

REM Verify images are loaded
echo.
echo Verifying images are loaded...
docker image inspect psychological-testing-main:latest >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: psychological-testing-main:latest image not found in Docker
    echo Please check if the image was loaded successfully
    exit /b 1
)

docker image inspect psychological-testing-llm:latest >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: psychological-testing-llm:latest image not found in Docker
    echo Please check if the image was loaded successfully
    exit /b 1
)

echo All images verified successfully
echo.
echo ==========================================
echo Starting all services with docker-compose...
echo ==========================================
echo.

REM Start docker-compose
%DOCKER_COMPOSE_CMD% up %*

endlocal
