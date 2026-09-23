class_name PlayerManager
extends Node

const MAX_PLAYERS: int = 4
const KEYBOARD_LEFT := &"keyboard_left"
const KEYBOARD_RIGHT := &"keyboard_right"
const GAMEPAD := &"gamepad"
const KEYBOARD_DEVICE_ID := InputEvent.DEVICE_ID_KEYBOARD

## A player slot owns one Player. An empty source_key means the player is
## still in the world but is waiting for another input source to take over.
class Slot:
	extends RefCounted
	var player: Player
	var source_key: StringName
	var actions: Array[StringName] = []

@export var player_scene: PackedScene
@export var players_root: Node3D
# TODO: The terrain generation will supply these "safe" tiles, or will be implicit.
@export var spawn_points: Array[Marker3D] = []

var _slots: Array[Slot] = []
# Slot indexes whose players have disconnected their controller and can be reassigned.
var _released_slots: Array[int] = []
var _focused: bool = true


func _ready() -> void:
	assert(player_scene != null and players_root != null)
	assert(spawn_points.size() == MAX_PLAYERS, "Provide four separate spawn markers.")
	_slots.resize(MAX_PLAYERS)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


## Converts join input into one of the three binding profiles.
## The join key itself is never copied into a player's action set.
func _unhandled_input(event: InputEvent) -> void:
	if not _focused or event.is_echo():
		return

	if event is InputEventKey:
		if event.is_action_pressed(&"keyboard_left_join"):
			_join(KEYBOARD_LEFT, KEYBOARD_DEVICE_ID)
		elif event.is_action_pressed(&"keyboard_right_join"):
			_join(KEYBOARD_RIGHT, KEYBOARD_DEVICE_ID)
		else:
			return
	elif event is InputEventJoypadButton and event.is_action_pressed(&"gamepad_join"):
		_join(GAMEPAD, event.device)
	else:
		return

	get_viewport().set_input_as_handled()


## Gives an unassigned input source a player.
## Disconnected players are reused first; otherwise the next empty slot spawns one.
func _join(profile: StringName, device_id: int) -> void:
	var source_key := _source_key(profile, device_id)
	if _find_source(source_key) != -1:
		return

	# Reassign to any disconnected profiles first. To handle reconnections.
	if not _released_slots.is_empty():
		_assign_source(_released_slots.pop_front(), profile, device_id)
		return

	# Otherwise, spawn a new player.
	var index := _slots.find(null)
	if index == -1:
		return

	var player: Player = player_scene.instantiate()
	var slot := Slot.new()
	slot.player = player
	_slots[index] = slot
	_assign_source(index, profile, device_id)

	player.transform = players_root.global_transform.affine_inverse() * spawn_points[index].global_transform
	players_root.add_child(player)


## Connects a binding profile to one player slot.
##
## Copies template actions such as `gamepad_move_left` into actions owned by
## this player, such as `player_2_move_left`. This keeps every Player's
## InputSource independent even when two players use the same input type.
##
## Solution referenced from https://www.reddit.com/r/godot/comments/13ikz4u/best_way_to_handle_controller_input_for_local/
func _assign_source(index: int, profile: StringName, device_id: int) -> void:
	var slot := _slots[index]
	slot.source_key = _source_key(profile, device_id)

	var prefix := "player_%d_" % index
	# Only copies bindings from ACTIONS array.
	for control in InputSource.ACTIONS:
		var action := StringName(prefix + control)
		var template := StringName("%s_%s" % [profile, control])
		InputMap.add_action(action, InputMap.action_get_deadzone(template))
		# Key bindings in project settings must match template to be mapped properly.
		for original_event in InputMap.action_get_events(template):
			var event: InputEvent = original_event.duplicate()
			event.device = device_id
			InputMap.action_add_event(action, event)
		slot.actions.append(action)
	var input_source := InputSource.new(prefix)

	slot.player.set_input_source(input_source)
	slot.player.set_controls_enabled(_focused)


## Creates a stable identity for a binding profile and device.
## Examples: `keyboard_left_16` and `gamepad_3`.
func _source_key(profile: StringName, device_id: int) -> StringName:
	return StringName("%s_%d" % [profile, device_id])


## Returns the slot currently controlled by this input source, if any.
func _find_source(key: StringName) -> int:
	for index in range(_slots.size()):
		var slot := _slots[index]
		if slot != null and slot.source_key == key:
			return index
	return -1


## Releases a player when its assigned controller disconnects.
## The Player stays in the world but cannot move until another source joins.
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		return

	var index := _find_source(_source_key(GAMEPAD, device_id))
	if index == -1:
		return

	var slot := _slots[index]
	slot.source_key = &""
	slot.player.set_controls_enabled(false)
	_remove_actions(slot)
	_released_slots.append(index)


## Disables movement while the game window is unfocused and restores it on return.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_focused(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_set_focused(true)


## Applies the current window-focus state to every assigned player.
func _set_focused(focused: bool) -> void:
	_focused = focused
	for slot in _slots:
		if slot != null:
			slot.player.set_controls_enabled(_focused and not slot.source_key.is_empty())


## Removes actions created at runtime for a slot's previous input source.
func _remove_actions(slot: Slot) -> void:
	for action in slot.actions:
		Input.action_release(action)
		InputMap.erase_action(action)
	slot.actions.clear()


## Cleans up all runtime InputMap actions when this level is unloaded.
func _exit_tree() -> void:
	for slot in _slots:
		if slot != null:
			_remove_actions(slot)
