extends Node3D

var opened : bool = false
@export var locked : bool = true
@export var keyhole : Marker3D

func toggle_door():
	if $AnimationPlayer.current_animation != "open" and $AnimationPlayer.current_animation != "close" and !locked:
		opened = !opened
		if opened:
			$AnimationPlayer.play("open")
		else:
			$AnimationPlayer.play("close")

func unlock():
	locked = false

func try_unlock_with(key) -> void:
	if locked and key != null and key.door == self:
		key.insert_into_door()
