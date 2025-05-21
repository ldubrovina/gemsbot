# Этап сборки
FROM python:3.12.3-slim-bookworm AS builder

# Настройка apt и репозиториев
RUN echo "deb http://mirror.yandex.ru/debian/ bookworm main contrib non-free" > /etc/apt/sources.list && \
  echo "deb http://mirror.yandex.ru/debian-security/ bookworm-security main contrib non-free" >> /etc/apt/sources.list

# Установка build-time зависимостей с повторными попытками
RUN for i in $(seq 1 3); do \
  apt-get clean && \
  apt-get update -o Acquire::http::Timeout=240 -y && \
  apt-get install -y --no-install-recommends \
  gcc \
  python3-dev && \
  rm -rf /var/lib/apt/lists/* && break || \
  if [ $i -lt 3 ]; then sleep 15; fi; \
  done

# Создание и активация виртуального окружения
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копирование и установка зависимостей
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Финальный этап
FROM python:3.12.3-slim-bookworm

# Копирование виртуального окружения из builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Настройка apt и репозиториев
RUN echo "deb http://mirror.yandex.ru/debian/ bookworm main contrib non-free" > /etc/apt/sources.list && \
  echo "deb http://mirror.yandex.ru/debian-security/ bookworm-security main contrib non-free" >> /etc/apt/sources.list

# Установка системных зависимостей с повторными попытками
RUN for i in $(seq 1 3); do \
  apt-get clean && \
  apt-get update -o Acquire::http::Timeout=240 -y && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  imagemagick \
  libmagickwand-dev && \
  rm -rf /var/lib/apt/lists/* && break || \
  if [ $i -lt 3 ]; then sleep 15; fi; \
  done

# Настройка политик ImageMagick
RUN mkdir -p /etc/ImageMagick-6 && \
  echo '<policymap>' > /etc/ImageMagick-6/policy.xml && \
  echo '  <policy domain="resource" name="memory" value="256MiB"/>' >> /etc/ImageMagick-6/policy.xml && \
  echo '  <policy domain="resource" name="map" value="512MiB"/>' >> /etc/ImageMagick-6/policy.xml && \
  echo '  <policy domain="resource" name="width" value="16KP"/>' >> /etc/ImageMagick-6/policy.xml && \
  echo '  <policy domain="resource" name="height" value="16KP"/>' >> /etc/ImageMagick-6/policy.xml && \
  echo '</policymap>' >> /etc/ImageMagick-6/policy.xml

# Создание и переход в рабочую директорию
WORKDIR /app

# Копируем конфигурационные файлы и ассеты
COPY settings.json settings_default.json ./
COPY game_assets/ ./game_assets/

# Копируем исходный код
COPY bot.py init_db.py ./
COPY data_source/ ./data_source/
COPY game_constants/ ./game_constants/
COPY jobs/ ./jobs/
COPY models/ ./models/
COPY templates/ ./templates/
COPY *.py ./

# Создаем необходимые директории и настраиваем разрешения
RUN mkdir -p /app/data /app/logs && \
  chmod 644 /app/settings*.json && \
  chmod -R 644 /app/game_assets/* && \
  chmod 755 /app/game_assets && \
  chown -R nobody:nogroup /app/data /app/logs

# Задаем переменные окружения
ENV PYTHONUNBUFFERED=1

# Метки для контейнера
LABEL maintainer="ldubrovina" \
  description="GoW Discord Bot" \
  version="1.0"

# Создаем entrypoint файл с проверкой наличия файлов
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
  echo 'echo "Checking required files..."' >> /app/entrypoint.sh && \
  echo 'ls -la /app/game_assets/' >> /app/entrypoint.sh && \
  echo 'if [ ! -f "/app/game_assets/GemsOfWar_English.json" ]; then' >> /app/entrypoint.sh && \
  echo '    echo "ERROR: Required file GemsOfWar_English.json not found!"' >> /app/entrypoint.sh && \
  echo '    exit 1' >> /app/entrypoint.sh && \
  echo 'fi' >> /app/entrypoint.sh && \
  echo 'echo "Starting bot..."' >> /app/entrypoint.sh && \
  echo 'python init_db.py' >> /app/entrypoint.sh && \
  echo 'exec python bot.py' >> /app/entrypoint.sh && \
  chmod +x /app/entrypoint.sh

# Запускаем через entrypoint
CMD ["/bin/sh", "/app/entrypoint.sh"]
