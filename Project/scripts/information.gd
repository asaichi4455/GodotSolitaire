class_name Information
extends Control

var _time: float = 0
var _score: int = 0
var _move: int = 0

@onready var _label_time: Label = $Time
@onready var _label_score: Label = $Score
@onready var _label_move: Label = $Move

var time: float:
    get:
        return _time
    set(value):
        _time = value
        var t := _time as int
        var hour := t / 60 / 60
        var minute = t / 60 % 60
        var second = t % 60
        _label_time.text = "%01d:%02d:%02d" % [hour, minute, second]

var score: int:
    get:
        return _score
    set(value):
        _score = value
        if _score < 0:
             _score = 0
        _label_score.text = "スコア　%d" % _score

var move: int:
    get:
        return _move
    set(value):
        _move = value
        _label_move.text = "移動回数　%d" % _move


func clear() -> void:
    time = 0
    score = 0
    move = 0
