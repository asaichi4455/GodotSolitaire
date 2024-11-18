class_name MouseEventSender
extends Node2D

enum State {
    BUTTON_DOWN,
    BUTTON_DRAG,
    NONE
}

const DRAG_THRESHOLD: int = 5

var _state := State.NONE
var _press_pos := Vector2.ZERO
var _prev_pos := Vector2.ZERO
var _target: MouseEventReceiver


func _physics_process(delta: float) -> void:
    var cur_pos = get_global_mouse_position()
    
    var space_state := get_world_2d().direct_space_state
    var query := PhysicsPointQueryParameters2D.new()
    query.position = cur_pos
    var result := space_state.intersect_point(query)
    result = result.filter(func(r: Dictionary): return r.collider is MouseEventReceiver)
    result.sort_custom(func(a: Dictionary, b: Dictionary): return a.collider.priority > b.collider.priority)
    
    match _state:
        State.BUTTON_DOWN:
            if Input.is_action_just_released("mouse_left"):
                _target.clicked.emit()
                _target = null
                _state = State.NONE
            elif _press_pos.distance_to(get_global_mouse_position()) > DRAG_THRESHOLD:
                _target.drag_began.emit(cur_pos)
                _state = State.BUTTON_DRAG
        
        State.BUTTON_DRAG:
            if Input.is_action_just_released("mouse_left"):
                _target.drag_ended.emit(cur_pos)
                _target = null
                _state = State.NONE
            elif cur_pos != _prev_pos:
                _target.dragged.emit(cur_pos - _prev_pos)
        
        State.NONE:
            if Input.is_action_just_pressed("mouse_left"):
                if result.size() > 0:
                    _target = result.front().collider as MouseEventReceiver
                    _press_pos = cur_pos
                    _state = State.BUTTON_DOWN
    
    _prev_pos = cur_pos
