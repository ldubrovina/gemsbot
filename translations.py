import json
import os

import humanize
from game_assets import GameAssets

LANGUAGES = {
    'en': 'English',
    'fr': 'French',
    'de': 'German',
    'ru': 'Russian',
    'ру': 'Russian',
    'it': 'Italian',
    'es': 'Spanish',
    'zh': 'Chinese',
    'cn': 'Chinese',
}

LANGUAGE_CODE_MAPPING = {
    'ру': 'ru',
    'cn': 'zh',
}

LOCALE_MAPPING = {
    'en': 'en_GB',
    'ru': 'ru_RU',
    'de': 'de_DE',
    'it': 'it_IT',
    'fr': 'fr_FR',
    'es': 'es_ES',
    'zh': 'zh_CN',
}

LANG_FILES = [f'GemsOfWar_{language}.json' for language in LANGUAGES.values()]


class Translations:
    BASE_LANG = 'en'

    def __init__(self):
        self.all_translations = {}
        # Загружаем только базовый язык (английский) и русский, так как он установлен по умолчанию
        languages_to_load = {'en': 'English', 'ru': 'Russian'}
        for lang_code, language in languages_to_load.items():
            try:
                self.all_translations[lang_code] = GameAssets.load(
                    f'GemsOfWar_{language}.json')
                addon_filename = f'extra_translations/{language}.json'
                if os.path.exists(addon_filename):
                    with open(addon_filename, encoding='utf8') as f:
                        addon_translations = json.load(f)
                    self.all_translations[lang_code].update(addon_translations)
            except FileNotFoundError:
                print(f"Warning: Could not load translations for {language}")
                if lang_code == self.BASE_LANG:
                    raise  # Если не можем загрузить базовый язык, выбрасываем ошибку

    def get(self, key, lang='', default=None, plural=False):
        if lang not in self.all_translations:
            lang = self.BASE_LANG
        if not default:
            default = key
        result = self.all_translations[lang].get(key, default)
        return self.pluralize(result, plural)

    @staticmethod
    def pluralize(text: str, plural: bool):
        if not text or '\x19' not in text:
            return text
        fragments = text.split('\x19')
        del fragments[2 - plural]
        return ''.join(fragments)


class HumanizeTranslator:
    def __init__(self, lang):
        self.lang = lang

    def __enter__(self):
        if self.lang.lower() != 'en':
            return humanize.i18n.activate(self.lang)

    def __exit__(self, exception_type, exception_value, traceback):
        humanize.i18n.deactivate()


# Создаем глобальный экземпляр переводчика
_instance = Translations()

def _(key: str, lang: str = 'en', default: str = None, plural: bool = False) -> str:
    """Глобальная функция перевода"""
    return _instance.get(key, lang, default, plural)
