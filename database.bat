@echo off
REM Script to seed the database with test and question data
REM Usage: seed-database.bat [SQL_FILE]

setlocal enabledelayedexpansion

REM Default SQL file
if "%~1"=="" (
    set SQL_FILE=seed-database.sql
) else (
    set SQL_FILE=%~1
)

echo ==========================================
echo Seeding database with test data
echo ==========================================
echo.

REM Check if docker-compose is available
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

REM Check if SQL file exists
if not exist "%SQL_FILE%" (
    echo Error: SQL file '%SQL_FILE%' not found
    echo Usage: seed-database.bat [SQL_FILE]
    exit /b 1
)

REM Check if PostgreSQL container is running
%DOCKER_COMPOSE_CMD% ps psql | findstr /C:"Up" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PostgreSQL container is not running
    echo Please start the services first: %DOCKER_COMPOSE_CMD% up -d
    exit /b 1
)

echo Loading SQL file: %SQL_FILE%
echo.

REM Execute SQL file in PostgreSQL container
type "%SQL_FILE%" | %DOCKER_COMPOSE_CMD% exec -T psql psql -U postgres -d postgres

if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo Database seeded successfully!
    echo ==========================================
) else (
    echo.
    echo Error: Failed to seed database
    exit /b 1
)

endlocal

