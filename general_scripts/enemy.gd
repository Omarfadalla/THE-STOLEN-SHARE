extends CharacterBody3D

@export var patrol_destinations: Array[Node3D]
@export var speed: float = 6.0
@export var chase_speed: float = 9.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player: Node3D = get_tree().current_scene.get_node_or_null("player")

var destination: Node3D
var destination_value: int = -1
var chasing: bool = false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	add_to_group("enemy")

	# Snap onto the navmesh at startup so a bad spawn height can't
	# strand the agent on the wrong floor before gravity even runs.
	call_deferred("_snap_to_navmesh")

	if patrol_destinations.size() > 0:
		pick_destination()
	else:
		push_warning("enemy.gd: patrol_destinations is empty, enemy will not move.")

func _snap_to_navmesh() -> void:
	await get_tree().physics_frame
	var map_rid = nav_agent.get_navigation_map()
	var closest = NavigationServer3D.map_get_closest_point(map_rid, global_transform.origin)
	if closest != Vector3.ZERO:
		global_transform.origin = closest

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if destination != null:
		var current_speed = chase_speed if chasing else speed
		var next_pos = nav_agent.get_next_path_position()
		var to_next = next_pos - global_transform.origin
		to_next.y = 0.0

		if to_next.length() > 0.05:
			var dir = to_next.normalized()
			velocity.x = move_toward(velocity.x, dir.x * current_speed, current_speed * 4.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * current_speed, current_speed * 4.0 * delta)

			var target_yaw = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, 0.15)
		else:
			velocity.x = move_toward(velocity.x, 0.0, current_speed * 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, current_speed * 4.0 * delta)

		move_and_slide()

		if nav_agent.is_navigation_finished():
			pick_destination(destination_value)

func pick_destination(dont_choose: int = -1) -> void:
	if patrol_destinations.is_empty():
		return
	var num = rng.randi_range(0, patrol_destinations.size() - 1)
	if patrol_destinations.size() > 1:
		while num == dont_choose:
			num = rng.randi_range(0, patrol_destinations.size() - 1)
	destination_value = num
	destination = patrol_destinations[num]
	nav_agent.target_position = destination.global_transform.origin
