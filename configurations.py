import os
from collections import ChainMap
from dotenv import load_dotenv

import hjson as json

# Загружаем переменные окружения в самом начале
load_dotenv()

class Configurations:
    DEFAULTS_FILE = 'settings_default.json'
    CONFIG_FILE = 'settings.json'

    def __init__(self):
        with open(self.DEFAULTS_FILE) as f:
            self.defaults = json.load(f)
        self.raw_config = {}
        if os.path.exists(self.CONFIG_FILE):
            with open(self.CONFIG_FILE) as f:
                self.raw_config = json.load(f)
        self.config = ChainMap(self.raw_config, self.defaults)

    def get(self, key, default=None):
        return self.config.get(key, default)


CONFIG = Configurations()
TOKEN = os.getenv('DISCORD_TOKEN')
if not TOKEN:
    raise ValueError("DISCORD_TOKEN environment variable is not set. Please set it with your Discord bot token.")
