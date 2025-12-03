# Запуск проекта через Docker Compose

Этот документ описывает, как запустить весь проект (бекенды, фронтенд, PostgreSQL и Ollama) через Docker Compose.

## Требования

- **Git** - для клонирования репозиториев
- **Docker** и **Docker Compose** установлены на вашей системе
- **Java 21+** и **Gradle** (для сборки бекендов, или используйте Gradle Wrapper)
- Минимум 4GB свободной оперативной памяти (рекомендуется 8GB+)
- Для GPU поддержки Ollama: NVIDIA Docker runtime (опционально)

## Быстрый старт

### Вариант 1: Полная установка с клонированием репозиториев (рекомендуется для первого запуска)

**Для Linux/macOS:**
```bash
./setup-and-run.sh
```

**Для Windows:**
```cmd
setup-and-run.bat
```

Скрипт автоматически:
1. Клонирует репозитории Backend и Frontend (если их еще нет)
2. Собирает образы бекендов через ktor `buildImage`
3. Загружает образы в Docker
4. Запускает все сервисы через docker-compose

### Вариант 2: Если репозитории уже клонированы

**Для Linux/macOS:**
```bash
./build-and-run.sh
```

**Для Windows:**
```cmd
build-and-run.bat
```

Скрипт соберет образы и запустит docker-compose.

### Вариант 3: Ручная сборка

Если репозитории уже клонированы, можно собрать образы вручную:

```bash
# Собрать main backend
cd Backend/main
./gradlew :main:buildImage -x detekt --no-daemon
docker load < main/build/jib-image.tar

# Собрать llm backend
./gradlew :llm:buildImage -x detekt --no-daemon
docker load < llm/build/jib-image.tar

cd ../..

# Запустить все сервисы
docker-compose up
```

Или в фоновом режиме:
```bash
docker-compose up -d
```

3. Дождитесь запуска всех сервисов. Это может занять несколько минут при первом запуске, так как:
   - Собираются образы бекендов (Gradle сборка)
   - Собирается образ фронтенда (npm build)
   - Скачиваются образы PostgreSQL и Ollama
   - Инициализируется база данных

4. После запуска сервисы будут доступны по следующим адресам:
   - **Фронтенд**: http://localhost:3000
   - **Main Backend API**: http://localhost:1488
   - **LLM Backend API**: http://localhost:1489
   - **PostgreSQL**: localhost:4343
   - **Ollama**: http://localhost:11434

   **Примечание**: Если порт 3000 уже занят, используйте переменную окружения:
   ```bash
   FRONTEND_PORT=8080 ./build-and-run.sh
   ```

## Настройка Ollama

После первого запуска Ollama необходимо загрузить модель. Выполните:

```bash
docker exec -it psychological-testing-ollama ollama pull qwen3:8b
```

Или используйте другую модель, указанную в конфигурации.

**Важно**: Загрузка модели может занять много времени и места на диске (несколько GB). Убедитесь, что у вас достаточно свободного места.

## Структура сервисов

- **psql**: PostgreSQL база данных
- **ollama**: LLM сервис для обработки текста
- **llm**: Бекенд сервис для работы с LLM
- **main**: Основной бекенд сервис
- **frontend**: React фронтенд приложение

## Конфигурация

Конфигурационные файлы для Docker окружения находятся в:
- `Backend/main/main/run/docker/application.conf` - конфигурация main бекенда
- `Backend/main/llm/run/docker/application.conf` - конфигурация llm бекенда

Эти файлы используют имена сервисов Docker Compose вместо localhost для связи между сервисами.

## Переменные окружения

Вы можете настроить порт фронтенда через переменную окружения:

```bash
FRONTEND_PORT=8080 docker-compose up
```

## Остановка сервисов

Для остановки всех сервисов:
```bash
docker-compose down
```

Для остановки и удаления volumes (удалит данные БД и Ollama):
```bash
docker-compose down -v
```

## Логи

Просмотр логов всех сервисов:
```bash
docker-compose logs -f
```

Просмотр логов конкретного сервиса:
```bash
docker-compose logs -f main
docker-compose logs -f llm
docker-compose logs -f frontend
```

## Решение проблем

### Сервисы не запускаются

1. Проверьте логи: `docker-compose logs`
2. Убедитесь, что порты не заняты другими приложениями
3. Проверьте, что достаточно свободной памяти

### Порт 3000 уже занят

Если порт 3000 занят другим приложением, используйте другой порт:
```bash
FRONTEND_PORT=8080 ./build-and-run.sh
```

Или измените порт в `docker-compose.yml` напрямую.

### Ошибка с платформой (linux/amd64 vs linux/arm64)

Если вы видите предупреждение о несоответствии платформы:
- На Apple Silicon (M1/M2/M3/M4) образы собираются для `linux/arm64` автоматически
- В `docker-compose.yml` указана платформа `linux/arm64` для бекендов
- Если нужна поддержка amd64, уберите `platform: linux/arm64` из docker-compose.yml

### Бекенд не может подключиться к БД

1. Убедитесь, что PostgreSQL запустился: `docker-compose ps`
2. Проверьте логи PostgreSQL: `docker-compose logs psql`
3. Дождитесь полной инициализации БД (может занять 10-30 секунд)

### Ollama не работает

1. Убедитесь, что модель загружена: `docker exec psychological-testing-ollama ollama list`
2. Если нужна GPU поддержка, раскомментируйте секцию `deploy` в docker-compose.yml для сервиса ollama

### Фронтенд не подключается к бекенду

1. Проверьте, что main бекенд запущен: `docker-compose ps`
2. Убедитесь, что переменная `VITE_API_BASE_URL` правильно установлена при сборке
3. Пересоберите фронтенд: `docker-compose build frontend`
