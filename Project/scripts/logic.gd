class_name Logic
extends RefCounted

signal moved_stock_to_waste(card: CardInfo, order: int)
signal moved_waste_to_stock
signal moved_waste(card: CardInfo, order: int)
signal moved_waste_full
signal moved_to_pile(card: CardInfo, pile_index: int, order: int)
signal moved_to_foundation(card: CardInfo, order: int, is_clear: bool)
signal moved_to_prev(card: CardInfo)
signal moved_one_step(step: Define.CardMoveStep)
signal game_cleared

var _cards: Array[CardInfo]
var _drop_rect: Define.CardDropRect
var _num_turn_to_waste: int = 1
var _is_enable_move: Callable

var num_turn_to_waste: int:
    set(value):
        _num_turn_to_waste = value

var is_enable_move: Callable:
    set(value):
        _is_enable_move = value


func init(cards: Array[CardInfo], rect: Define.CardDropRect) -> void:
    _cards = cards
    _drop_rect = rect
    for card in cards:
        card.clicked.connect(func(c: CardInfo): _clicked(c))
        card.drag_began.connect(_drag_began)
        card.drag_ended.connect(func(c: CardInfo, position: Vector2): _drag_ended(c, position))


func deal_cards(num_piles: int) -> void:
    var index: int = 0
    for p in num_piles:
        for o in p + 1:
            var card: CardInfo = _cards[index]
            card.card_type = Define.CardType.PILE
            card.pile_index = p
            card.order = o
            card.is_facedown = false if o == p else true
            card.clickable = true if o == p else false
            moved_to_pile.emit(card, p, o)
            index += 1


func set_cards_game_clear() -> void:
    for i in _cards.size():
        if _cards[i].card_type != Define.CardType.FOUNDATION:
            _cards[i].card_type = Define.CardType.FOUNDATION
            _cards[i].order = _cards[i].number as int
            moved_to_foundation.emit(_cards[i], _cards[i].order, true)


func stock_clicked() -> void:
    var is_enable: bool = _is_enable_move.call()
    if not is_enable:
        return

    # 山札を難易度に応じて1枚か3枚めくる
    # 山札がなくなればめくったカードをすべて山札にもどす
    var num_stock := _cards\
            .filter(func(c: CardInfo): return c.card_type == Define.CardType.STOCK)\
            .size()
    if num_stock > 0:
        var waste_cards: Array[CardInfo] = _cards\
                .filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE)
        var waste_top: Array[CardInfo] = waste_cards.slice(0, Game.MAX_WASTES)
        waste_top.reverse()

        var turn_cards: Array[CardInfo] = _cards\
                .filter(func(c: CardInfo): return c.card_type == Define.CardType.STOCK)\
                .slice(-_num_turn_to_waste, _cards.size())
        turn_cards.reverse()

        # 枚数分カードをめくる
        for i in turn_cards.size():
            turn_cards[i].card_type = Define.CardType.WASTE
            turn_cards[i].clickable = false
            var order: int = clampi(waste_cards.size(), 0, Game.MAX_WASTES)
            if order + turn_cards.size() - 1 > Game.MAX_WASTES - 1:
                order -= (order + turn_cards.size() - 1 - (Game.MAX_WASTES - 1))
            order += i
            turn_cards[i].order = order
        
        for i in turn_cards.size():
            moved_stock_to_waste.emit(turn_cards[i], turn_cards[i].order)

        # めくられていたカードを奥に移動
        # 手前のカードのみ操作可能とする
        for card in waste_top:
            card.clickable = false
        
        var num_waste_top := waste_top.size()
        var num_turn_cards := turn_cards.size()
        if num_waste_top + num_turn_cards > Game.MAX_WASTES:
            for i in waste_top.size():
                var order: int = clampi(i - (num_waste_top + num_turn_cards - Game.MAX_WASTES), 0, Game.MAX_WASTES - 1)
                waste_top[i].order = order
                moved_waste.emit(waste_top[i], order)
        _cards.filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE).front().clickable = true
        moved_one_step.emit(Define.CardMoveStep.STOCK_TO_WASTE)
    else:
        # すべて山札に戻す
        var waste_cards: Array[CardInfo] = _cards\
                .filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE)
        if waste_cards.size() > 0:
            for i in waste_cards.size():
                waste_cards[i].card_type = Define.CardType.STOCK
                waste_cards[i].clickable = false
            moved_waste_to_stock.emit()
            moved_one_step.emit(Define.CardMoveStep.WASTE_TO_STOCK)


func _waste_to_foundation(card: CardInfo, suit: Define.Suit) -> void:
    # 組札に移動
    card.order = card.number as int
    card.card_type = Define.CardType.FOUNDATION
    moved_to_foundation.emit(card, card.order, false)
    
    if Utility.is_game_clear(_cards, _num_turn_to_waste):
        game_cleared.emit()
    else:
        # すでにめくったカードを補充
        var waste: Array[CardInfo] = _cards\
                .filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE)\
                .slice(0, Game.MAX_WASTES)
        waste.reverse()
        if waste.size() > 0:
            for i in waste.size():
                waste[i].order = i
            waste.back().clickable = true
            moved_waste_full.emit()

    moved_one_step.emit(Define.CardMoveStep.WASTE_TO_FOUNDATION)


func _waste_to_pile(card: CardInfo, pile_index: int) -> void:
    # 場札に移動
    card.order = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)\
            .size()
    card.card_type = Define.CardType.PILE
    card.pile_index = pile_index

    # 移動先の場札の位置を更新
    var pile_cards: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)
    for i in pile_cards.size():
        moved_to_pile.emit(pile_cards[i], pile_cards[i].pile_index, pile_cards[i].order)

    # すでにめくったカードを補充
    var waste: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE)\
            .slice(0, Game.MAX_WASTES)
    waste.reverse()
    if waste.size() > 0:
        for i in waste.size():
            waste[i].order = i
        waste.back().clickable = true
        moved_waste_full.emit()

    moved_one_step.emit(Define.CardMoveStep.WASTE_TO_PILE)


func _pile_to_foundation(card: CardInfo, suit: Define.Suit) -> void:
    var src_pile_index := card.pile_index

    # 組札に移動
    card.order = card.number as int
    card.card_type = Define.CardType.FOUNDATION
    moved_to_foundation.emit(card, card.order, false)

    if Utility.is_game_clear(_cards, _num_turn_to_waste):
        game_cleared.emit()
    else:
        # 移動元の場札の列の先頭カードをめくる
        var src_pile_cards: Array[CardInfo] = _cards\
                .filter(func(c: CardInfo):
                        return c.card_type == Define.CardType.PILE and c.pile_index == src_pile_index)
        src_pile_cards.sort_custom(func(a: CardInfo, b: CardInfo): return a.order < b.order)
        if src_pile_cards.size() > 0:
            for i in src_pile_cards.size():
                moved_to_pile.emit(src_pile_cards[i], src_pile_cards[i].pile_index, src_pile_cards[i].order)

            var bottom_card: CardInfo = src_pile_cards.back() as CardInfo
            if bottom_card.is_facedown:
                bottom_card.clickable = true
                bottom_card.is_facedown = false
                moved_one_step.emit(Define.CardMoveStep.FACEUP_PILE)

    moved_one_step.emit(Define.CardMoveStep.PILE_TO_FOUNDATION)


func _foundation_to_pile(card: CardInfo, pile_index: int) -> void:
    # 場札に移動
    card.order = _cards\
            .filter(func(c: CardInfo):\
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)\
            .size()
    card.card_type = Define.CardType.PILE
    card.pile_index = pile_index

    # 移動先の場札の位置を更新
    var pile_cards: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)
    for i in pile_cards.size():
        moved_to_pile.emit(pile_cards[i], pile_cards[i].pile_index, pile_cards[i].order)

    moved_one_step.emit(Define.CardMoveStep.FOUNDATION_TO_PILE)


func _pile_to_pile(card: CardInfo, pile_index: int, connected_cards: Array[CardInfo]) -> void:
    var src_pile_index := card.pile_index

    # 場札に移動
    card.order = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)\
            .size()
    card.card_type = Define.CardType.PILE
    card.pile_index = pile_index

    # 連続したカードを同時に移動
    for i in connected_cards.size():
        connected_cards[i].order = card.order + i + 1
        connected_cards[i].card_type = Define.CardType.PILE
        connected_cards[i].pile_index = pile_index

    # 移動先の場札の位置を更新
    var pile_cards: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)
    for i in pile_cards.size():
        moved_to_pile.emit(pile_cards[i], pile_cards[i].pile_index, pile_cards[i].order)

    # 移動元の場札の列の先頭カードをめくる
    var src_pile_cards: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == src_pile_index)
    src_pile_cards.sort_custom(func(a: CardInfo, b: CardInfo): return a.order < b.order)
    if src_pile_cards.size() > 0:
        for i in src_pile_cards.size():
            moved_to_pile.emit(src_pile_cards[i], src_pile_cards[i].pile_index, src_pile_cards[i].order)

        var bottom_card: CardInfo = src_pile_cards.back() as CardInfo
        if bottom_card.is_facedown:
            bottom_card.clickable = true
            bottom_card.is_facedown = false
            moved_one_step.emit(Define.CardMoveStep.FACEUP_PILE)

    moved_one_step.emit(Define.CardMoveStep.PILE_TO_PILE)


func _clicked(card: CardInfo) -> void:
    var is_enable: bool = _is_enable_move.call()
    if not is_enable:
        return

    match card.card_type:
        Define.CardType.STOCK:
            pass

        Define.CardType.WASTE:
            var result_move_to_foundation: Dictionary = Utility.try_move_to_foundation(_cards, card)
            var result_move_to_pile: Dictionary = Utility.try_move_to_pile(_cards, card)
            
            # 山札からめくったカード -> 組札の移動判定
            if result_move_to_foundation["result"]:
                _waste_to_foundation(card, result_move_to_foundation["suit"])
            
            # 山札からめくったカード -> 場札の移動判定
            elif result_move_to_pile["result"]:
                _waste_to_pile(card, result_move_to_pile["pile_index"])

        Define.CardType.PILE:
            var connected_cards: Array[CardInfo] = Utility.get_connected_cards(_cards, card)
            var result_move_to_foundation: Dictionary = Utility.try_move_to_foundation(_cards, card)
            var result_move_to_pile: Dictionary = Utility.try_move_to_pile(_cards, card)
            
            # 場札 -> 組札の移動判定
            if connected_cards.size() == 0 and result_move_to_foundation["result"]:
                _pile_to_foundation(card, result_move_to_foundation["suit"])
            
            # 場札 -> 場札の移動判定
            elif result_move_to_pile["result"]:
                _pile_to_pile(card, result_move_to_pile["pile_index"], connected_cards)

        Define.CardType.FOUNDATION:
            var result_move_to_pile: Dictionary = Utility.try_move_to_pile(_cards, card)
            
            # 組札 -> 場札の移動判定
            if result_move_to_pile["result"]:
                var pile_index: int = result_move_to_pile["pile_index"]
                
                # 場札に移動
                card.order = _cards\
                        .filter(func(c: CardInfo):
                                return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)\
                        .size()
                card.card_type = Define.CardType.PILE
                card.pile_index = pile_index

                # 移動先の場札の位置を更新
                var pile_cards: Array[CardInfo] = _cards\
                        .filter(func(c: CardInfo):
                                return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)
                for i in pile_cards.size():
                    moved_to_pile.emit(pile_cards[i], pile_cards[i].pile_index, pile_cards[i].order)

                moved_one_step.emit(Define.CardMoveStep.FOUNDATION_TO_PILE)


func _drag_began(card: CardInfo, position: Vector2) -> void:
    var is_enable: bool = _is_enable_move.call()
    if is_enable:
        card.is_drag = true


func _drag_ended(card: CardInfo, position: Vector2) -> void:
    if not card.is_drag:
        return

    var is_enable: bool = _is_enable_move.call()
    if not is_enable:
        return

    match card.card_type:
        Define.CardType.STOCK:
            pass

        Define.CardType.WASTE:
            var move := false

            # 山札からめくったカード -> 組札の移動判定
            for i in _drop_rect.foundations.size():
                if (
                        _drop_rect.foundations[i].intersects(Rect2(card.to_global(card.rect.position), card.rect.size))
                        and Utility.can_move_to_foundation(_cards, card, i as Define.Suit)
                ):
                    _waste_to_foundation(card, i as Define.Suit)
                    move = true
                    break

            # 山札からめくったカード -> 場札の移動判定
            for i in _drop_rect.piles.size():
                if (
                        _drop_rect.piles[i].intersects(Rect2(card.to_global(card.rect.position), card.rect.size))
                        and Utility.can_move_to_pile(_cards, card, i)
                ):
                    _waste_to_pile(card, i)
                    move = true
                    break

            if not move:
                moved_to_prev.emit(card)

        Define.CardType.PILE:
            var move := false
            var connected_cards: Array[CardInfo] = Utility.get_connected_cards(_cards, card)

            # 場札 -> 組札の移動判定
            if connected_cards.size() == 0:
                for i in _drop_rect.foundations.size():
                    if (
                            _drop_rect.foundations[i].intersects(Rect2(card.to_global(card.rect.position), card.rect.size))
                            and Utility.can_move_to_foundation(_cards, card, i as Define.Suit)
                    ):
                        _pile_to_foundation(card, i as Define.Suit)
                        move = true
                        break

            # 場札 -> 場札の移動判定
            for i in _drop_rect.piles.size():
                if (
                        _drop_rect.piles[i].intersects(Rect2(card.to_global(card.rect.position), card.rect.size))
                        and Utility.can_move_to_pile(_cards, card, i)
                ):
                    _pile_to_pile(card, i, connected_cards)
                    move = true
                    break

            if not move:
                moved_to_prev.emit(card)

        Define.CardType.FOUNDATION:
            var move := false

            # 組札 -> 場札の移動判定
            for i in _drop_rect.piles.size():
                if (
                        _drop_rect.piles[i].intersects(Rect2(card.to_global(card.rect.position), card.rect.size))
                        and Utility.can_move_to_pile(_cards, card, i)
                ):
                    _foundation_to_pile(card, i)
                    move = true
                    break

            if not move:
                moved_to_prev.emit(card)

    card.is_drag = false
