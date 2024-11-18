class_name Utility
extends RefCounted


static func get_num_turn_to_waste(difficulty: Define.Difficulty) -> int:
    var ret: int = 1
    match difficulty:
        Define.Difficulty.EASY: ret = 1
        Define.Difficulty.HARD: ret = 3
    return ret


static func try_move_to_pile(cards: Array[CardInfo], card: CardInfo) -> Dictionary:
    var ret := {"result": false, "pile_index": 0}
    for pile_index in Game.NUM_PILES:
        if can_move_to_pile(cards, card, pile_index):
            ret["result"] = true
            ret["pile_index"] = pile_index
            break
    return ret


static func can_move_to_pile(cards: Array[CardInfo], card: CardInfo, pile_index: int) -> bool:
    var ret := false
    var filtered: Array[CardInfo] = cards\
            .filter(func(card: CardInfo):
                    return card.card_type == Define.CardType.PILE and card.pile_index == pile_index)
    filtered.sort_custom(func(a: CardInfo, b: CardInfo): return a.order < b.order)
    var c: CardInfo = null if filtered.is_empty() else filtered.back()

    if c == null:
        if card.number == Define.Number.K:
            ret = true
        return ret

    if (
            (c.suit == Define.Suit.HEART or c.suit == Define.Suit.DIAMOND)
            and (card.suit == Define.Suit.CLUB or card.suit == Define.Suit.SPADE)
    ):
        if c.number == card.number + 1:
            ret = true
    
    elif (
            (c.suit == Define.Suit.CLUB or c.suit == Define.Suit.SPADE)
            and (card.suit == Define.Suit.HEART or card.suit == Define.Suit.DIAMOND)
    ):
        if c.number == card.number + 1:
            ret = true
    
    return ret


static func try_move_to_foundation(cards: Array[CardInfo], card: CardInfo) -> Dictionary:
    var ret := {"result": false, "suit": Define.Suit.HEART}
    for suit in Define.Suit.NUM:
        if can_move_to_foundation(cards, card, suit):
            ret["result"] = true
            ret["suit"] = suit
            break
    return ret


static func can_move_to_foundation(cards: Array[CardInfo], card: CardInfo, suit: Define.Suit) -> bool:
    var ret := false

    if card.suit != suit:
        return ret

    var filtered: Array[CardInfo] = cards\
            .filter(func(card: CardInfo):
                    return card.card_type == Define.CardType.FOUNDATION and card.suit == suit)
    filtered.sort_custom(func(a: CardInfo, b: CardInfo): return a.order < b.order)
    var c: CardInfo = null if filtered.is_empty() else filtered.back()

    if c == null:
        if card.number == Define.Number.A:
            ret = true
        return ret

    if card.suit == c.suit and card.number == c.number + 1:
        ret = true
    return ret


static func get_connected_cards(cards: Array[CardInfo], card: CardInfo) -> Array[CardInfo]:
    if card.card_type != Define.CardType.PILE:
        return []

    var ret = cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE\
                    and c.pile_index == card.pile_index\
                    and c.order > card.order)
    ret.sort_custom(func(a: CardInfo, b: CardInfo): return a.order < b.order)
    return ret


static func is_game_clear(cards: Array[CardInfo], num_turn_to_waste: int) -> bool:
    if cards.any(func(c: CardInfo): return c.card_type == Define.CardType.PILE and c.is_facedown):
        return false

    if cards.any(func(c: CardInfo): return c.card_type == Define.CardType.STOCK):
        return false
    
    var num_waste := cards.filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE).size()
    if num_turn_to_waste > 1 and num_waste > 1:
        return false

    return true
