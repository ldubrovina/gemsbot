import asyncio
import datetime
import os
import json

from discord.ext import tasks
from game_assets import GameAssets

from base_bot import log
from configurations import CONFIG
from jobs.news_downloader import NewsDownloader
from jobs.status_reporter import StatusReporter
from search import TeamExpander, update_translations
from translations import LANG_FILES


@tasks.loop(minutes=1, reconnect=True)
async def task_report_status(discord_client):
    status = StatusReporter()
    await status.update(discord_client)


@tasks.loop(minutes=1, reconnect=True)
async def task_update_pet_rescues(discord_client):
    lock = asyncio.Lock()
    async with lock:
        discord_client.pet_rescues = [rescue for rescue in discord_client.pet_rescues if rescue.active]
    for rescue in discord_client.pet_rescues:
        e = discord_client.views.render_pet_rescue(rescue)
        await rescue.create_or_edit_posts(e)


@tasks.loop(minutes=CONFIG.get('news_check_interval_minutes'), reconnect=False)
async def task_check_for_news(discord_client):
    lock = asyncio.Lock()
    async with lock:
        try:
            downloader = NewsDownloader(discord_client.session)
            await downloader.process_news_feed()
            await discord_client.show_latest_news()
        except Exception as e:
            log.error('Could not update news. Stacktrace follows.')
            log.exception(e)


@tasks.loop(seconds=CONFIG.get('file_update_check_seconds'))
async def task_check_for_data_updates(discord_client):
    filenames = LANG_FILES + ['World.json', 'Soulforge.json', 'Event.json', 'Store.json']
    now = datetime.datetime.now()
    modified_files = []
    for filename in filenames:
        file_path = GameAssets.path(filename)
        try:
            modification_time = datetime.datetime.fromtimestamp(os.path.getmtime(file_path))
        except FileNotFoundError:
            continue
        modified = now - modification_time <= datetime.timedelta(seconds=CONFIG.get('file_update_check_seconds'))
        if modified:
            modified_files.append(filename)
    if modified_files:
        log.debug(f'Game file modification detected, reloading {", ".join(modified_files)}.')
        await asyncio.sleep(5)
        lock = asyncio.Lock()
        async with lock:
            try:
                old_expander = discord_client.expander
                del discord_client.expander

                # Инициализируем пустые пользовательские данные чтобы убрать отладочные сообщения
                discord_client.expander = TeamExpander()
                discord_client.expander.user_data = {}

                update_translations()
            except Exception as e:
                log.error('Could not update game file. Stacktrace follows.')
                log.exception(e)
                discord_client.expander = old_expander


@tasks.loop(hours=24)  # Проверяем раз в день
async def task_update_game_data(discord_client):
    """Обновляет World.json и GemsOfWar_Russian.json из удаленного источника"""
    files_to_update = {
        'World.json': 'https://garyatrics.com/game-data/World.json',
        'GemsOfWar_Russian.json': 'https://garyatrics.com/game-data/GemsOfWar_Russian.json'
    }

    for filename, url in files_to_update.items():
        file_path = os.path.join('game_assets', filename)
        try:
            async with discord_client.session.get(url) as response:
                if response.status == 200:
                    new_data = await response.json()
                    # Сохраняем резервную копию текущего файла
                    if os.path.exists(file_path):
                        backup_path = file_path + '.backup'
                        os.replace(file_path, backup_path)

                    # Записываем новые данные
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(new_data, f, indent=2)

                    log.info(f'{filename} успешно обновлен')
                else:
                    log.error(f'Не удалось загрузить {filename}: HTTP {response.status}')
                    continue

        except Exception as e:
            log.error(f'Ошибка при обновлении {filename}')
            log.exception(e)
            continue

    # После обновления всех файлов перезагружаем данные в боте
    lock = asyncio.Lock()
    async with lock:
        try:
            old_expander = discord_client.expander
            discord_client.expander = TeamExpander()
            discord_client.expander.user_data = {}
            update_translations()
            log.info('Данные успешно перезагружены')
        except Exception as e:
            log.error('Ошибка при перезагрузке данных')
            log.exception(e)
            discord_client.expander = old_expander
