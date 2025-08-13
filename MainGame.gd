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

var spike_area: Area3D
var spike_joint: Joint3D

var cached_dama: RigidBody3D
var cached_ken: PhysicsBody3D
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

	# Connect hole area signals
	var hole_area := dama.get_node("PivotPoint/RigidBody3D/HoleArea3D") as Area3D
	spike_area = ken.get_node("PivotPoint/KenController/Spike/SpikeArea3D") as Area3D
	hole_area.area_entered.connect(_on_hole_entered)
	hole_area.area_exited.connect(_on_hole_exited)

	if hole_area:
		hole_area.monitoring = true
		hole_area.monitorable = true
		hole_area.collision_layer = 1
		hole_area.collision_mask = 1
		if not hole_area.is_connected("area_entered", Callable(self, "_on_hole_area_body_entered")):
			hole_area.area_entered.connect(_on_hole_area_body_entered)
		if not hole_area.is_connected("area_exited", Callable(self, "_on_hole_area_body_exited")):
			hole_area.area_exited.connect(_on_hole_area_body_exited)
		# Debug
		hole_area.area_entered.connect(func(a): print("[DBG] hole area_entered:", a.name, " groups:", a.get_groups()))
		hole_area.body_entered.connect(func(b): print("[DBG] hole body_entered:", b.name, " groups:", b.get_groups()))

	if spike_area:
		spike_area.monitoring = true
		spike_area.monitorable = true
		spike_area.collision_layer = 1
		spike_area.collision_mask = 1
		# Debug
		spike_area.area_entered.connect(func(a): print("[DBG] spike area_entered:", a.name, " groups:", a.get_groups()))

	cached_dama = kendama_manager.get_dama_body()
	cached_ken = kendama_manager.get_ken_body() as PhysicsBody3D

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

func _on_hole_entered(a: Area3D) -> void:
	if a == spike_area:
		var dama_body: RigidBody3D = kendama_manager.get_dama_body()
		var ken_body: PhysicsBody3D = kendama_manager.get_ken_body() as PhysicsBody3D
		if dama_body and ken_body:
			dama_body.add_collision_exception_with(ken_body)
			var joint := Generic6DOFJoint3D.new()
			joint.node_a = dama_body.get_path()
			joint.node_b = ken_body.get_path()
			# Align the joint frame to the spike so sliding uses the spike's axis
			joint.global_transform = spike_area.global_transform
			# Lock lateral motion; allow sliding along the spike axis (assumed local Y)
			joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
			joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
			joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
			joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
			joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.25)
			joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.05)
			joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
			joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
			joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
			# Lock rotation to keep the hole aligned to the spike
			joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
			joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
			joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
			joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
			joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
			joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
			add_child(joint)
			spike_joint = joint

func _on_hole_exited(a: Area3D) -> void:
	if a == spike_area:
		var dama_body: RigidBody3D = kendama_manager.get_dama_body()
		var ken_body: PhysicsBody3D = kendama_manager.get_ken_body() as PhysicsBody3D
		if spike_joint and is_instance_valid(spike_joint):
			spike_joint.queue_free()
			spike_joint = null
		if dama_body and ken_body:
			dama_body.remove_collision_exception_with(ken_body)
