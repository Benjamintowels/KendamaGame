extends Node

signal left_pressed
signal left_released
signal right_pressed
signal right_released
signal mouse_motion(relative: Vector2, position: Vector2)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				emit_signal("left_pressed")
			else:
				emit_signal("left_released")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				emit_signal("right_pressed")
			else:
				emit_signal("right_released")
	elif event is InputEventMouseMotion:
		emit_signal("mouse_motion", event.relative, event.position)


