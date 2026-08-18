extends SpotLight3D

@onready var player = get_tree().current_scene.get_node("player")

@export var forward_offset := 0.3
@export var up_offset := 0.1
@export var wall_clear_margin := 0.1

func _process(delta: float) -> void:
	var desired = player.global_transform.origin \
		+ player.global_transform.basis.z * -forward_offset \
		+ player.global_transform.basis.y * up_offset

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(player.global_transform.origin, desired)
	query.exclude = [player]
	var result = space_state.intersect_ray(query)

	if result:
		var dir = (desired - player.global_transform.origin).normalized()
		global_transform.origin = result.position - dir * wall_clear_margin
	else:
		global_transform.origin = desired

func _physics_process(delta: float) -> void:
	var rot_y = lerp_angle(global_rotation.y, player.global_rotation.y, 0.2)
	var rot_x = lerp_angle(global_rotation.x, player.global_rotation.x, 0.2)
	var rot_z = lerp_angle(global_rotation.z, player.global_rotation.z, 0.2)
	global_rotation.y = rot_y
	global_rotation.x = rot_x
	global_rotation.z = rot_z
