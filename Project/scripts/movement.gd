class_name Movement
extends RefCounted

const WASTE_OFFSET_Y: int = 16
const PILE_OFFSET_Y: int = 16
const MIN_PILE_OFFSET_Y: int = 6
const DRAG_CARD_Z_INDEX: int = 100

var _cards: Array[CardInfo]
var _coordinates: Define.CardCoordinates
var _pile_drop_rect:  Array[Rect2]
var _is_animate: Dictionary
var _scene_tree: SceneTree

var is_animate: bool:
    get:
        return _is_animate.values().any(func(value: bool): return value)


func init(cards: Array[CardInfo], cardCoordinates: Define.CardCoordinates, pile_drop_bounds: Array[Rect2], scene_tree: SceneTree):
    _cards = cards
    _coordinates = cardCoordinates
    _pile_drop_rect = pile_drop_bounds
    _scene_tree = scene_tree
    for i in cards.size():
        cards[i].drag_began.connect(func(card: CardInfo, position: Vector2): _drag_began(card, position))
        cards[i].dragged.connect(func(card: CardInfo, position: Vector2): _dragged(card, position))
        _is_animate[cards[i]] = false


func prepare_stock() -> void:
    for i in _cards.size():
        _cards[i].position = _coordinates.stock


func move_stock_to_waste(card: CardInfo, order: int) -> void:
    var num_waste := _cards.filter(func(c: CardInfo):
            return c.card_type == Define.CardType.WASTE)\
            .size()
    var pos := _coordinates.waste
    pos.y += (order * WASTE_OFFSET_Y)
    card.is_facedown = false
    card.z_index = num_waste + order
    _animate_async(card, pos)


func move_waste_to_stock() -> void:
    for i in _cards.size():
        if _cards[i].card_type == Define.CardType.STOCK:
            _cards[i].is_facedown = true
            _cards[i].z_index = i
            _animate_async(_cards[i], _coordinates.stock)


func move_waste(card: CardInfo, order: int) -> void:
    var pos := _coordinates.waste
    pos.y += (order * WASTE_OFFSET_Y)
    _animate_async(card, pos)


func move_waste_full() -> void:
    var waste: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo): return c.card_type == Define.CardType.WASTE)\
            .slice(0, Game.MAX_WASTES)
    waste.reverse()
    
    for i in waste.size():
        var pos := _coordinates.waste
        pos.y += (i * WASTE_OFFSET_Y)
        _animate_async(waste[i], pos)


func move_to_pile(card: CardInfo, pile_index: int, order: int) -> void:
    # 枚数に応じて間隔を調整
    var pile_cards: Array[CardInfo] = _cards\
            .filter(func(c: CardInfo):
                    return c.card_type == Define.CardType.PILE and c.pile_index == pile_index)
    pile_cards.sort_custom(func(a: CardInfo, b: CardInfo): return a.order < b.order)
    var offset_facedown := PILE_OFFSET_Y
    var offset_faceup := PILE_OFFSET_Y
    var card_height := card.size.y
    var height_over := card_height + (pile_cards.size() - 1) * PILE_OFFSET_Y - _pile_drop_rect[pile_index].size.y
    if height_over > 0:
        var num_facedown := pile_cards.filter(func(c: CardInfo): return c.is_facedown).size()
        var num_faceup := pile_cards.size() - num_facedown
        offset_facedown -= ceili(height_over / num_facedown)
        offset_facedown = clampi(offset_facedown, MIN_PILE_OFFSET_Y, PILE_OFFSET_Y)
        height_over = card_height + num_facedown * offset_facedown + (num_faceup - 1) * offset_faceup - _pile_drop_rect[pile_index].size.y
        if height_over > 0:
            offset_faceup -= ceili(height_over / (num_faceup - 1))
            offset_faceup = clampi(offset_faceup, MIN_PILE_OFFSET_Y, PILE_OFFSET_Y)

    var pos := _coordinates.piles[pile_index]
    for i in pile_cards.size():
        if pile_cards[i].order == order:
            break
        pos.y += offset_facedown if pile_cards[i].is_facedown else offset_faceup

    card.z_index = DRAG_CARD_Z_INDEX + order
    await  _animate_async(card, pos)
    card.z_index = order


func move_to_foundation(card: CardInfo, order: int, is_clear: bool) -> void:
    var pos := _coordinates.foundations[card.suit as int]
    card.z_index = DRAG_CARD_Z_INDEX + order
    if is_clear:
        _animate_async(card, pos)
    else:
        await _animate_async(card, pos)
        card.z_index = order


func move_to_prev(card: CardInfo) -> void:
    var connected_cards: Array[CardInfo]

    if card.card_type == Define.CardType.PILE:
        connected_cards = Utility.get_connected_cards(_cards, card)
        for i in connected_cards.size():
            _animate_async(connected_cards[i], connected_cards[i].prev_position)
    await _animate_async(card, card.prev_position)

    if card.card_type == Define.CardType.PILE:
        for i in connected_cards.size():
            connected_cards[i].z_index = connected_cards[i].prev_z_index
    card.z_index = card.prev_z_index


func _drag_began(card: CardInfo, position: Vector2) -> void:
    if is_animate:
        return

    card.prev_position = card.position
    card.prev_z_index = card.z_index
    card.z_index = DRAG_CARD_Z_INDEX + card.number as int

    if card.card_type == Define.CardType.PILE:
        var cards := Utility.get_connected_cards(_cards, card)
        for i in cards.size():
            cards[i].prev_position = cards[i].position
            cards[i].prev_z_index = cards[i].z_index
            cards[i].z_index = DRAG_CARD_Z_INDEX + card.number as int + i + 1


func _dragged(card: CardInfo, position: Vector2) -> void:
    if is_animate or not card.is_drag:
        return

    card.position = position

    if card.card_type == Define.CardType.PILE:
        var cards := Utility.get_connected_cards(_cards, card)
        for i in cards.size():
            var p = card.position
            p.y += ((cards[i].order - card.order) * WASTE_OFFSET_Y)
            cards[i].position = p


func _animate_async(card: CardInfo, dst: Vector2) -> void:
    _is_animate[card] = true

    while true:
        await _scene_tree.create_timer(0.03).timeout
        var pos = card.position
        var x := lerpf(pos.x, dst.x, 0.4)
        var y := lerpf(pos.y, dst.y, 0.4)
        if abs(dst.x - x) < 1:
             x = dst.x
        if abs(dst.y - y) < 1:
             y = dst.y
        card.position = Vector2(x, y)
        if is_equal_approx(x, dst.x) and is_equal_approx(y, dst.y):
            _is_animate[card] = false
            break

    _is_animate[card] = false
