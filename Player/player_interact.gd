extends RayCast3D

@onready var player_ui = get_tree().current_scene.get_node("player/player_ui")
@onready var crosshair = player_ui.get_node("crosshair")
@export var key_hold : Node3D

var carried_key = null

func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		if hit.name == "safe":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				player_ui.open_safe_password()
		elif hit.is_in_group("key"):
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.hit_obj(key_hold)
				carried_key = hit
		elif hit.name == "door":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				var door_root = hit.get_parent().get_parent().get_parent()
				if door_root.locked:
					door_root.try_unlock_with(carried_key)
				else:
					door_root.toggle_door()
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
		elif hit.name == "left_door":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().toggle_fence_gate()
		elif hit.name == "right_door":
			if not crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().toggle_fence_gate()
		else:
			if crosshair.visible:
				crosshair.visible = false
	else:
		if crosshair.visible:
			crosshair.visible = false
