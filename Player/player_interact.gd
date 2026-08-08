extends RayCast3D

@onready var crosshair = get_tree().current_scene.get_node("player/player_ui")


func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()

		if hit.name == "door":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().get_parent().get_parent().toggle_door()
		elif hit.name == "light_switch":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().toggle_lights()
		elif hit.name == "door_bell":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().ring_bell()
		else:
			if crosshair.visible:
				crosshair.visible = false
	else:
		if crosshair.visible:
			crosshair.visible = false
