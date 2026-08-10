extends Node3D

@export var on : bool = false
@export var on_mat : StandardMaterial3D
@export var off_mat : StandardMaterial3D
@export var bulb_name : String = ""

var light_bulb : Node3D

func _ready() -> void:
	on = false
	light_bulb = get_tree().current_scene.find_child(bulb_name, true, false)
	if light_bulb == null:
		push_warning("light_switch couldn't find a bulb named: " + bulb_name)
		return
	_update_lights()

func toggle_lights() -> void:
	on = !on
	_update_lights()

func _update_lights() -> void:
	if light_bulb == null:
		return
	$on.visible = on
	$off.visible = !on
	if light_bulb.has_method("set_bulb_state"):
		light_bulb.set_bulb_state(on)
	else:
		push_warning("Bulb '" + bulb_name + "' has no set_bulb_state method.")
