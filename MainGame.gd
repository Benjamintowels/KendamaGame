extends Node3D

@onready var ken = $KendamaContainer/Ken
@onready var dama = $KendamaContainer/Dama
@onready var camera = $Camera3D

# Managers
@onready var input_manager = $InputManager
@onready var camera_manager = $CameraManager
@onready var physics_manager = $PhysicsManager
@onready var kendama_manager = $KendamaManager

# String physics parameters
var string_length = 2.0
var string_stiffness = 50.0
var string_damping = 5.0
var tug_force = 15.0

# Mouse control variables
var last_mouse_pos = Vector2.ZERO
var mouse_sensitivity = 0.01



func _ready():
	# Wire managers
	camera_manager.camera = camera
	kendama_manager.ken = ken
	kendama_manager.dama = dama
	
	# Connect input events
	input_manager.left_pressed.connect(kendama_manager.left_pressed)
	input_manager.left_released.connect(kendama_manager.left_released)
	input_manager.right_pressed.connect(kendama_manager.right_pressed)
	input_manager.right_released.connect(kendama_manager.right_released)
	input_manager.mouse_motion.connect(_on_mouse_motion)

	# Set up physics
	setup_physics()

func _on_mouse_motion(relative: Vector2, mouse_position: Vector2) -> void:
	# Tug force
	var dama_body = kendama_manager.get_dama_body()
	if dama_body:
		physics_manager.apply_tug(dama_body, relative, mouse_sensitivity)
	# Ken 1:1 movement (super rigid): snap every input event to world position
	var world = camera_manager.screen_to_world(mouse_position)
	kendama_manager.move_ken_to(world)

func setup_physics():
	# Get the rigid bodies
	var ken_body = kendama_manager.get_ken_body()
	var dama_body = kendama_manager.get_dama_body()
	
	# Set up dama physics
	if dama_body:
		dama_body.gravity_scale = 1.0
		dama_body.linear_damp = 0.5
		dama_body.angular_damp = 0.8
	
	# Set up ken physics for direct mouse control
	# If ken is a rigid body, adjust; otherwise (StaticBody3D), nothing needed
	if ken_body and ken_body is RigidBody3D:
		var rb := ken_body as RigidBody3D
		rb.gravity_scale = 0.0
		rb.linear_damp = 0.0
		rb.angular_damp = 0.0
		rb.mass = 1.0
	
	# Set collision layers
	if ken_body:
		ken_body.collision_layer = 1
		ken_body.collision_mask = 2
	if dama_body:
		dama_body.collision_layer = 2
		dama_body.collision_mask = 1



func handle_mouse_movement(_relative_movement):
	# Deprecated: handled by PhysicsManager via _on_mouse_motion
	pass

func handle_ken_movement(_mouse_position):
	# Deprecated: handled by CameraManager+KendamaManager via _on_mouse_motion
	pass

func _physics_process(delta):
	# Keep Ken snapped each physics tick to last mouse position for rigidity
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var world = camera_manager.screen_to_world(mouse_pos)
	kendama_manager.move_ken_to(world)
	# Apply string physics
	apply_string_physics(delta)

func apply_string_physics(_delta):
	var ken_body = kendama_manager.get_ken_body()
	var dama_body = kendama_manager.get_dama_body()
	
	if ken_body == null or dama_body == null:
		return

	# Delegate to physics manager
	physics_manager.apply_string(ken_body, dama_body)

func _on_hole_area_body_entered(body):
	# Check if the ken spike entered the dama hole
	if body.is_in_group("ken_spike"):
		print("Ken spike entered dama hole!")

func _on_hole_area_body_exited(body):
	# Check if the ken spike exited the dama hole
	if body.is_in_group("ken_spike"):
		print("Ken spike exited dama hole!")
