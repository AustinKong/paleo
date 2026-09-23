class_name PlayerMovement
extends Node

@export_range(0.0, 20.0) var max_speed: float = 2.0
@export_range(0.0, 100.0) var acceleration: float = 30.0
@export_range(0.0, 100.0) var deceleration: float = 30.0
@export_range(0.0, 50.0) var turn_speed: float = 15.0

var _body: CharacterBody3D


func initialize(body: CharacterBody3D) -> void:
	assert(body != null, "Movement requires a body.")
	_body = body


func step(move_input: Vector2, delta: float) -> void:
	var direction := Vector3(move_input.x, 0.0, move_input.y).limit_length()

	var planar_velocity := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	var rate := deceleration if direction.is_zero_approx() else acceleration
	_body.velocity = planar_velocity.move_toward(direction * max_speed, rate * delta)

	if not direction.is_zero_approx():
		var target_angle := atan2(-direction.x, -direction.z)
		_body.rotation.y = rotate_toward(_body.rotation.y, target_angle, turn_speed * delta)

	_body.move_and_slide()


func stop() -> void:
	_body.velocity = Vector3.ZERO
