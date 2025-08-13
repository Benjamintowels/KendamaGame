extends Node

@export var camera: Camera3D

func screen_to_world(mouse_position: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	# Map screen to world via ray-plane intersection with Z=0 plane
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_dir: Vector3 = camera.project_ray_normal(mouse_position)
	var plane_normal := Vector3(0, 0, 1)
	var plane_d := 0.0
	var denom := plane_normal.dot(ray_dir)
	if abs(denom) < 0.000001:
		# Fallback: keep origin XY, clamp Z to plane
		return Vector3(ray_origin.x, ray_origin.y, 0.0)
	var t := -(plane_normal.dot(ray_origin) + plane_d) / denom
	return ray_origin + ray_dir * t


