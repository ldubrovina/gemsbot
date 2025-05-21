# Этап сборки
FROM python:3.12.3-slim-bookworm as builder

# Установка build-time зависимостей
RUN apt-get update -y --fix-missing && \
  apt-get install -y --no-install-recommends \
  gcc \
  python3-dev \
  && rm -rf /var/lib/apt/lists/*

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

# Установка системных зависимостей
RUN apt-get update -y --fix-missing && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  imagemagick \
  libmagickwand-dev && \
  rm -rf /var/lib/apt/lists/*

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
