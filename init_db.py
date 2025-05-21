import sqlite3
import os

def init_db():
    # Подключаемся к базе данных
    conn = sqlite3.connect('db.sqlite3')
    cursor = conn.cursor()
    
    # Читаем файл схемы
    schema_path = os.path.join('models', 'schema.sql')
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema = f.read()
    
    # Выполняем SQL-запросы
    cursor.executescript(schema)
    
    # Сохраняем изменения и закрываем соединение
    conn.commit()
    conn.close()
    
    print("База данных успешно инициализирована!")

if __name__ == '__main__':
    init_db() 