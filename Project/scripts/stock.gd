class_name Stock
extends Sprite2D

signal clicked


func init() -> void:
    $MouseEventReceiver.clicked.connect(Callable(clicked.emit))
