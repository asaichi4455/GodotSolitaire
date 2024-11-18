class_name Card
extends RefCounted

var _suit := Define.Suit.HEART
var _number := Define.Number.A

var suit: Define.Suit:
    get:
        return _suit
    set(value):
        _suit = value

var number: Define.Number:
    get:
        return _number
    set(value):
        _number = value
