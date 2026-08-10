extends Node3D

var omni : OmniLight3D

func _ready() -> void:
	print("bulb node: ", name, " | OmniLight3D found: ", has_node("OmniLight3D"))
	if not has_node("OmniLight3D"):
		push_warning("No OmniLight3D child on: " + name)
		return
	omni = $OmniLight3D
	omni.visible = false

func set_bulb_state(state: bool) -> void:
	if omni:
		omni.visible = state
