class_name InputSource
extends RefCounted

## Reads one player's prefixed InputMap actions through common control names.
## This lets Player use the same movement and interaction code regardless of
## whether its source is a keyboard layout or a controller.
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const PICKUP_DROP := &"pickup_drop"
const INTERACT := &"interact"

const ACTIONS: Array[StringName] = [
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	PICKUP_DROP,
	INTERACT,
]

var _action_prefix: String


func _init(action_prefix: String) -> void:
	_action_prefix = action_prefix


func get_move_vector() -> Vector2:
	return Input.get_vector(
		_action(MOVE_LEFT), _action(MOVE_RIGHT),
		_action(MOVE_UP), _action(MOVE_DOWN)
	)


func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(_action(action))


func _action(action: StringName) -> StringName:
	return StringName(_action_prefix + action)
