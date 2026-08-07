extends RayCast3D
func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		if hit.name == "door":
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().get_parent().get_parent().toggle_door()
	if is_colliding():
		var hit = get_collider()
		if hit.name == "light_switch":
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().toggle_lights()
