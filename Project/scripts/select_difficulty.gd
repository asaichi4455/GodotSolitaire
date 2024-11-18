class_name SelectDifficulty
extends Control

signal selected(difficulty)
signal canceled

enum Dialog {
    INIT,
    NEW_GAME,
    GAME_CLEAR,
}

var type: Dialog:
    set(value):
        match value:
            Dialog.INIT:
                _label_title.text = "難易度を選択";
                _button_close.hide()
            
            Dialog.NEW_GAME:
                _label_title.text = "新しいゲームを\r\n開始しますか？";
                _button_close.show()
            
            Dialog.GAME_CLEAR:
                _label_title.text = "もう一度プレイ\r\nしますか？";
                _button_close.hide()

@onready var _label_title: Label = $Dialog/Title
@onready var _button_easy: Button = $Dialog/Easy
@onready var _button_hard: Button = $Dialog/Hard
@onready var _button_close: Button = $Dialog/Close


func init() -> void:
    _button_easy.pressed.connect(func(): selected.emit(Define.Difficulty.EASY))
    _button_hard.pressed.connect(func(): selected.emit(Define.Difficulty.HARD))
    _button_close.pressed.connect(func(): canceled.emit())
    visibility_changed.connect(_visibility_changed)


func _visibility_changed() -> void:
    $MouseEventReceiver/CollisionShape2D.disabled = not visible
