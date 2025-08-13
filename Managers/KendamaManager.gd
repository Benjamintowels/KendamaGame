extends Node

@export var ken: Node3D
@export var dama: Node3D

func get_ken_body() -> Node3D:
    if ken == null:
        return null
    var node := ken.get_node_or_null("KenController")
    if node == null:
        node = ken.find_child("KenController", true, false)
    return node as Node3D

func get_dama_body() -> RigidBody3D:
    if dama == null:
        return null
    var rb: RigidBody3D = dama.get_node_or_null("PivotPoint/RigidBody3D")
    if rb == null:
        # Fallback: first RigidBody3D under dama
        for child in dama.get_children():
            var found := child as RigidBody3D
            if found != null:
                return found
            # recursive search
            var deep := (child as Node).find_child("RigidBody3D", true, false)
            if deep is RigidBody3D:
                return deep
    return rb

func move_ken_to(world_position: Vector3) -> void:
    var ken_body: Node3D = get_ken_body()
    if ken_body == null:
        return
    # Preserve Z so movement stays locked to the Ken's current plane
    var locked = Vector3(world_position.x, world_position.y, ken_body.global_position.z)
    ken_body.global_position = locked

func left_pressed() -> void:
    ken.handle_left_click(true)

func left_released() -> void:
    ken.handle_left_click(false)

func right_pressed() -> void:
    ken.handle_right_click(true)

func right_released() -> void:
    ken.handle_right_click(false)

func debug_print_state() -> void:
    var node := get_ken_body()
    if node == null:
        print("[KenDebug] Ken controller not found")
        return
    print("[KenDebug] type:", node.get_class(), " rot_deg:", node.rotation_degrees)


