extends RayCast3D

@onready var player_ui = get_tree().current_scene.get_node("player/player_ui")
@onready var crosshair = player_ui.get_node("crosshair")


func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()

		if hit.name == "safe":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				player_ui.open_safe_password()
		elif hit.name == "door":
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
