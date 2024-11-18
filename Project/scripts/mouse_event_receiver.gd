class_name MouseEventReceiver
extends Node2D

signal clicked
signal drag_began(position: Vector2)
signal dragged(delta: Vector2)
signal drag_ended(position: Vector2)

var priority: int:
    get:
        var z := z_index
        var parent = get_parent()
        while parent is CanvasItem:
            z += parent.z_index
            parent = parent.get_parent()
        return z
