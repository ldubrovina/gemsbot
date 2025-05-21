import json
import os
import logging

from configurations import CONFIG

log = logging.getLogger(__name__)

class GameAssets:
    @staticmethod
    def load(filename):
        game_assets_folder = CONFIG.get('game_assets_folder')
        if not game_assets_folder:
            log.error("'game_assets_folder' is not defined in the configuration.")
            raise ValueError("Missing 'game_assets_folder' configuration.")
        path = os.path.join(game_assets_folder, filename)
        log.debug(f"Loading file: {path}")
        with open(path, encoding='utf8') as f:
            return json.load(f)

    @staticmethod
    def path(filename):
        return os.path.join(CONFIG.get('game_assets_folder'), filename)

    @staticmethod
    def exists(filename):
        path = os.path.join(CONFIG.get('game_assets_folder'), filename)
        log.debug(f"Checking existence of file: {path}")
        return os.path.exists(path)
