class_name PlayerAnimation
extends Node

# Presentation-only state; replace the placeholder with an animated model later.
var planar_speed: float = 0.0


func update_locomotion(planar_velocity: Vector3, _delta: float) -> void:
	planar_speed = Vector2(planar_velocity.x, planar_velocity.z).length()
