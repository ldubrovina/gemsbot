# public enum LiveEventsData.EventType
import logging

logger = logging.getLogger(__name__)

EVENT_TYPES = {
    0: '[GUILD_WARS]',
    1: '[RAIDBOSS]',
    2: '[INVASION]',
    3: '[VAULT]',
    4: '[BOUNTY]',
    5: '[PETRESCUE]',
    6: '[CLASS_EVENT]',
    7: '[DELVE_EVENT]',
    8: '[TOWER_OF_DOOM]',
    9: '[HIJACK]',
    10: '[WEEKLY_EVENT]',
    11: '[CAMPAIGN]',
    12: '[ARENA]',
    13: '[JOURNEY]',
    14: '[KINGDOM_PASS]',
    15: '[LEGENDS_REBORN]',
    16: '[HOLIDAYEVENT_TEAMS]',
    17: '[UNDERSPIRE]',
    18: '[PVP_SEASON]',
    19: 'SpecialWeeklyEvent',
}

def get_event_type(type_id):
    """Получает тип события по его ID. Если тип неизвестен, записывает предупреждение в журнал."""
    if type_id is None:
        logger.warning("Event type is None")
        return "Unknown"

    event_type = EVENT_TYPES.get(type_id)
    if event_type is None:
        logger.warning(f"Unknown event type: {type_id}")
        return f"Unknown({type_id})"

    return event_type
