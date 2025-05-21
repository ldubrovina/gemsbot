FROM python:3.12.3-slim-bookworm

# Установка системных зависимостей
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  imagemagick \
  && rm -rf /var/lib/apt/lists/*

# Создание и переход в рабочую директорию
WORKDIR /app

# Копирование файлов зависимостей
COPY requirements.txt .

# Установка зависимостей Python
RUN pip install --no-cache-dir -r requirements.txt

# Копируем код приложения
COPY . .

# Задаем переменные окружения
ENV PYTHONUNBUFFERED=1

# Создаем entrypoint файл
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
  echo 'python init_db.py' >> /app/entrypoint.sh && \
  echo 'exec python bot.py' >> /app/entrypoint.sh && \
  chmod +x /app/entrypoint.sh

# Запускаем через entrypoint
CMD ["/bin/sh", "/app/entrypoint.sh"]
