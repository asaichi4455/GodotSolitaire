class_name Game
extends Node2D

enum State {
    LOAD,
    SELECT_DIFFICULTY,
    PREPARE,
    PLAY,
    GAME_CLEAR,
}

const MAX_WASTES:int = 3
const NUM_PILES:int = 7
const SCORE: Dictionary = {
    Define.CardMoveStep.STOCK_TO_WASTE: 0,
    Define.CardMoveStep.WASTE_TO_STOCK: -100,
    Define.CardMoveStep.WASTE_TO_PILE: 5,
    Define.CardMoveStep.WASTE_TO_FOUNDATION: 10,
    Define.CardMoveStep.PILE_TO_PILE: 0,
    Define.CardMoveStep.PILE_TO_FOUNDATION: 15,
    Define.CardMoveStep.FOUNDATION_TO_PILE: -15,
    Define.CardMoveStep.FACEUP_PILE: 5,
}

var _state := State.LOAD
var _cards: Array[CardInfo]
var _logic := Logic.new()
var _movement := Movement.new()

@export var _select_difficulty: SelectDifficulty
@export var _new_game_button: Button
@export var _stock: Stock
@export var _waste: Node2D
@export var _piles: Node2D
@export var _foundations: Node2D
@export var _information: Information
@export var _audio: Audio


func _ready() -> void:
    _audio.init()
    init()
    _state = State.SELECT_DIFFICULTY


func _process(delta: float) -> void:
    match _state:
        State.LOAD:
            pass

        State.SELECT_DIFFICULTY:
            pass

        State.PREPARE:
            prepare_stock()
            deal_cards()
            _state = State.PLAY

        State.PLAY:
            var time: float = _information.time
            time += delta
            _information.time = time

        State.GAME_CLEAR:
            if not _movement.is_animate:
                _select_difficulty.type = SelectDifficulty.Dialog.GAME_CLEAR
                _select_difficulty.show()
                _state = State.SELECT_DIFFICULTY


func init() -> void:
    # カード生成
    for s in Define.Suit.NUM:
        for n in Define.Number.NUM:
            var card: CardInfo = preload("res://scenes/card.tscn").instantiate() as CardInfo
            card.init(s, n)
            card.hide()
            add_child(card)
            _cards.append(card)
    
    # 難易度選択
    _select_difficulty.init()
    _select_difficulty.selected.connect(func(difficulty):
            _select_difficulty.hide()
            _logic.num_turn_to_waste = Utility.get_num_turn_to_waste(difficulty)
            _information.clear()
            _state = State.PREPARE)
    _select_difficulty.canceled.connect(func(): _select_difficulty.hide())
    _select_difficulty.type = SelectDifficulty.Dialog.INIT
    _select_difficulty.show()

    # 新しいゲームボタン
    _new_game_button.pressed.connect(func():
            _select_difficulty.type = SelectDifficulty.Dialog.NEW_GAME
            _select_difficulty.show())

    # 山札
    _stock.init()
    _stock.clicked.connect(func(): _logic.stock_clicked())

    # ロジック制御
    var rect: = create_card_drop_rect()
    _logic.init(_cards, rect)
    _logic.moved_stock_to_waste.connect(_movement.move_stock_to_waste)
    _logic.moved_waste_to_stock.connect(_movement.move_waste_to_stock)
    _logic.moved_waste.connect(_movement.move_waste)
    _logic.moved_waste_full.connect(_movement.move_waste_full)
    _logic.moved_to_pile.connect(_movement.move_to_pile)
    _logic.moved_to_foundation.connect(_movement.move_to_foundation)
    _logic.moved_to_prev.connect(_movement.move_to_prev)
    _logic.moved_one_step.connect(func(step: Define.CardMoveStep):
            if step != Define.CardMoveStep.FACEUP_PILE:
                _information.move += 1
                _audio.move_one_step(step)
            _information.score += SCORE[step])
    _logic.game_cleared.connect(func():
            _logic.set_cards_game_clear()
            _state = State.GAME_CLEAR)
    _logic.is_enable_move = func(): return not _movement.is_animate

    # 移動制御
    _movement.init(_cards, create_card_coordinates(), rect.piles, get_tree())


func prepare_stock() -> void:
    # シャッフルして山札に配置
    _cards.shuffle()
    for i in _cards.size():
        _cards[i].card_type = Define.CardType.STOCK
        _cards[i].pile_index = 0
        _cards[i].order = i
        _cards[i].z_index = i
        _cards[i].clickable = false
        _cards[i].is_facedown = true
        _cards[i].show()
    _movement.prepare_stock()


func deal_cards() -> void:
    _logic.deal_cards(NUM_PILES)
    _audio.deal_cards()


func create_card_drop_rect() -> Define.CardDropRect:
    var rect := Define.CardDropRect.new()
    var piles := _piles.get_children()
    var foundations := _foundations.get_children()
    for i in piles.size():
        rect.piles.append(Rect2(
                _piles.to_global(piles[i].position),
                (piles[i] as Sprite2D).region_rect.size))
    for i in foundations.size():
        rect.foundations.append(Rect2(
                _foundations.to_global(foundations[i].position),
                (foundations[i] as Sprite2D).region_rect.size))
    return rect


func create_card_coordinates() -> Define.CardCoordinates:
    var coordinates := Define.CardCoordinates.new()
    var piles := _piles.get_children()
    var foundations := _foundations.get_children()
    coordinates.stock = _stock.position
    coordinates.waste = _waste.position
    for i in piles.size():
        coordinates.piles.append(_piles.to_global(piles[i].position))
    for i in foundations.size():
        coordinates.foundations.append(_foundations.to_global(foundations[i].position))
    return coordinates
