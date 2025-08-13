extends Node

@export var string_length: float = 2.0
@export var string_stiffness: float = 50.0
@export var string_damping: float = 5.0
@export var tug_force: float = 15.0

func apply_tug(dama_body: RigidBody3D, relative_mouse: Vector2, mouse_sensitivity: float) -> void:
	if relative_mouse.y < 0:
		var tug_vector = Vector3(0, -relative_mouse.y * tug_force * mouse_sensitivity, 0)
		dama_body.apply_central_force(tug_vector)

func apply_string(ken_body: Node3D, dama_body: RigidBody3D) -> void:
	var ken_pos = ken_body.global_position
	var dama_pos = dama_body.global_position
	var distance = ken_pos.distance_to(dama_pos)
	if distance <= string_length:
		return
	var direction = (ken_pos - dama_pos).normalized()
	# Force the string to act within the XY plane so Z stays constant
	direction.z = 0.0
	direction = direction.normalized()
	var force_magnitude = (distance - string_length) * string_stiffness
	var string_force = direction * force_magnitude
	var damping_force = -dama_body.linear_velocity * string_damping
	# Remove any Z damping so we don't pull out of plane
	damping_force.z = 0.0
	dama_body.apply_central_force(string_force + damping_force)


