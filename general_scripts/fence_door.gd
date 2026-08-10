extends Node3D

var opened : bool = false
@export var locked : bool = false

func toggle_fence_gate():
	if $AnimationPlayer.current_animation != "open" and !locked:
		opened = !opened
		if !opened:
			$AnimationPlayer.play_backwards("open")
		if opened:
			$AnimationPlayer.play("open")
