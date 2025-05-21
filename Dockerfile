# Этап сборки
FROM python:3.12.3-slim-bookworm AS builder

# Настройка apt для использования российских зеркал
RUN sed -i 's/deb.debian.org/mirror.yandex.ru/g' /etc/apt/sources.list && \
  sed -i 's/security.debian.org/mirror.yandex.ru/g' /etc/apt/sources.list

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

# Настройка apt для использования российских зеркал
RUN sed -i 's/deb.debian.org/mirror.yandex.ru/g' /etc/apt/sources.list && \
  sed -i 's/security.debian.org/mirror.yandex.ru/g' /etc/apt/sources.list

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

# Копируем только необходимые файлы
COPY bot.py init_db.py ./
COPY data_source/ ./data_source/
COPY game_constants/ ./game_constants/
COPY jobs/ ./jobs/
COPY models/ ./models/
COPY templates/ ./templates/
COPY *.py ./

# Создаем необходимые директории
RUN mkdir -p /app/data /app/logs /app/game_assets

# Задаем переменные окружения
ENV PYTHONUNBUFFERED=1

# Метки для контейнера
LABEL maintainer="ldubrovina" \
  description="GoW Discord Bot" \
  version="1.0"

# Создаем entrypoint файл
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
  echo 'python init_db.py' >> /app/entrypoint.sh && \
  echo 'exec python bot.py' >> /app/entrypoint.sh && \
  chmod +x /app/entrypoint.sh

# Запускаем через entrypoint
CMD ["/bin/sh", "/app/entrypoint.sh"]
