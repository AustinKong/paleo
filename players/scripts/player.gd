class_name Player
extends CharacterBody3D

var _input_source: InputSource
var _controls_enabled: bool = true

@onready var movement: PlayerMovement = %Movement
@onready var interaction: PlayerInteraction = %Interaction
@onready var animation: PlayerAnimation = %Animation


func _ready() -> void:
	assert(_input_source != null, "Set Player input before adding it to the scene.")
	movement.initialize(self)
	interaction.initialize(self)


func _physics_process(delta: float) -> void:
	if not _controls_enabled:
		return

	movement.step(_input_source.get_move_vector(), delta)
	interaction.step(
		_input_source.is_action_just_pressed(InputSource.PICKUP_DROP),
		_input_source.is_action_just_pressed(InputSource.INTERACT)
	)
	animation.update_locomotion(get_real_velocity(), delta)


func set_input_source(input_source: InputSource) -> void:
	assert(input_source != null, "Player requires an input source.")
	_input_source = input_source


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled

	if is_node_ready() and not enabled:
		movement.stop()
		animation.update_locomotion(Vector3.ZERO, 0.0)
