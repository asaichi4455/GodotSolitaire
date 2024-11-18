class_name CardInfo
extends Node2D

signal clicked(card: CardInfo)
signal drag_began(card: CardInfo, position:Vector2)
signal dragged(card: CardInfo, position:Vector2)
signal drag_ended(card: CardInfo, position:Vector2)

var _card := Card.new()
var _card_type := Define.CardType.STOCK
var _pile_index: int = 0
var _order: int = 0
var _is_drag: bool = false
var _prev_position := Vector2.ZERO
var _prev_z_index: int = 0

var suit: Define.Suit:
    get:
        return _card.suit

var number: Define.Number:
    get:
        return _card.number

var card_type: Define.CardType:
    get:
        return _card_type
    set(value):
        _card_type = value

var pile_index: int:
    get:
        return _pile_index
    set(value):
        _pile_index = value

var order: int:
    get:
        return _order
    set(value):
        _order = value

var is_drag: bool:
    get:
        return _is_drag
    set(value):
        _is_drag = value

var prev_position: Vector2:
    get:
        return _prev_position
    set(value):
        _prev_position = value

var prev_z_index: int:
    get:
        return _prev_z_index
    set(value):
        _prev_z_index = value

var clickable: bool:
    set(value):
        $Sprite2D/MouseEventReceiver/CollisionShape2D.set_deferred("disabled", not value)

var is_facedown: bool:
    get:
        return $Sprite2D.region_rect == Define.CARD_TEXTURE_REGION_FACEDOWN
    set(value):
        $Sprite2D.region_rect = Define.CARD_TEXTURE_REGION_FACEDOWN if value\
                else Define.CARD_TEXTURE_REGION[_card.suit][_card.number]

var size: Vector2:
    get:
        return $Sprite2D.region_rect.size

var rect: Rect2:
    get:
        return Rect2($Sprite2D.position, size)


func init(suit: Define.Suit, number:Define.Number):
    _card.suit = suit
    _card.number = number
    $Sprite2D.region_rect = Define.CARD_TEXTURE_REGION[_card.suit][_card.number]

    var mouse_event_receiver = $Sprite2D/MouseEventReceiver
    mouse_event_receiver.clicked.connect(func(): clicked.emit(self))
    mouse_event_receiver.drag_began.connect(func(position: Vector2): drag_began.emit(self, position))
    mouse_event_receiver.dragged.connect(func(delta: Vector2): dragged.emit(self, position + delta))
    mouse_event_receiver.drag_ended.connect(func(position: Vector2): drag_ended.emit(self, position))
