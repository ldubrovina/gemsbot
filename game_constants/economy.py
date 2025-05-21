import logging

logger = logging.getLogger(__name__)

def process_economy_model(data):
    """
    Обрабатывает экономическую модель игровых данных.
    Если модель отсутствует, записывает предупреждение в журнал и возвращает значения по умолчанию.
    """
    if 'pEconomyModel' not in data:
        logger.warning("Missing 'pEconomyModel' in user_data")
        return {
            'souls': 0,
            'gold': 0,
            'gems': 0,
            'guild_seals': 0
        }

    return data['pEconomyModel']
