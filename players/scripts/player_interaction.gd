class_name PlayerInteraction
extends Node

const DROP_DISTANCE: float = 0.8

var _player: Player
var _held_item: Pickupable

@onready var _interaction_area: Area3D = %InteractionArea
@onready var _one_hand_anchor: Node3D = %OneHandAnchor
@onready var _two_hand_anchor: Node3D = %TwoHandAnchor


func initialize(player: Player) -> void:
	assert(player != null, "Interaction requires a player.")
	_player = player


func step(pickup_drop_pressed: bool, interact_pressed: bool) -> void:
	if pickup_drop_pressed:
		if _held_item == null:
			_pick_up_target()
		else:
			_drop_held_item()
		return

	if interact_pressed:
		_interact_with_target()


func _pick_up_target() -> void:
	var pickupable := _nearest_pickupable()
	if pickupable == null:
		return

	if pickupable.pick_up(_anchor_for(pickupable)):
		_held_item = pickupable


func _drop_held_item() -> void:
	var forward := -_player.global_transform.basis.z
	var drop_transform := _player.global_transform
	drop_transform.origin = _anchor_for(_held_item).global_position + forward * DROP_DISTANCE

	if _held_item.drop(drop_transform, _player.velocity):
		_held_item = null


func _interact_with_target() -> void:
	if _held_item == null:
		return

	var tool := _tool_on(_held_item.get_body())
	if tool == null:
		return

	var target := _nearest_target_for(tool)
	if target != null:
		tool.interact(target)


func _nearest_pickupable() -> Pickupable:
	var nearest: Pickupable
	var nearest_distance_squared := INF

	for body in _interaction_area.get_overlapping_bodies():
		var pickupable := _pickupable_on(body)
		if pickupable == null:
			continue

		var distance_squared := _interaction_area.global_position.distance_squared_to(body.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = pickupable
			nearest_distance_squared = distance_squared

	return nearest


func _nearest_target_for(tool: Tool) -> Node3D:
	var nearest: Node3D
	var nearest_distance_squared := INF

	for body in _interaction_area.get_overlapping_bodies():
		if not tool.can_interact_with(body):
			continue

		var distance_squared := _interaction_area.global_position.distance_squared_to(body.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = body
			nearest_distance_squared = distance_squared

	return nearest


func _pickupable_on(node: Node) -> Pickupable:
	for child in node.get_children():
		if child is Pickupable:
			return child
	return null


func _tool_on(node: Node) -> Tool:
	for child in node.get_children():
		if child is Tool:
			return child
	return null


func _anchor_for(pickupable: Pickupable) -> Node3D:
	if pickupable.carry_anchor == Pickupable.CarryAnchor.TWO_HAND:
		return _two_hand_anchor
	return _one_hand_anchor
