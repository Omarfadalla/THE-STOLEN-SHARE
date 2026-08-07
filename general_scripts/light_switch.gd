extends Node3D
@export var on : = false
@export var on_mat : StandardMaterial3D
@export var off_mat : StandardMaterial3D
@export var bulb_name : String = ""  # just type the bulb's node name here, e.g. "bulb", "bulb2", "bulb3"

var light_bulb : Node3D

func _ready() -> void:
	light_bulb = get_tree().current_scene.find_child(bulb_name, true, false)
	if light_bulb == null:
		push_warning("light_switch couldn't find a bulb named: " + bulb_name)
		return
	_update_lights()

func toggle_lights():
	on = !on
	_update_lights()

func _update_lights():
	if light_bulb == null:
		return
	var mat = on_mat if on else off_mat
	$on.visible = on
	$off.visible = !on
	light_bulb.get_node("LED FLAT Base/light").material_override = mat
	light_bulb.get_node("LED FLAT Base/light2").material_override = mat
	light_bulb.get_node("OmniLight3D").visible = on
