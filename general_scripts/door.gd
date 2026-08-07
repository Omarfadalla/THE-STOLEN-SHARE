extends Node3D

var opened : bool = false

func toggle_door():
	if $AnimationPlayer.current_animation != "open" and $AnimationPlayer.current_animation != "close":
		opened = !opened
		if !opened:
			$AnimationPlayer.play("close")
		if opened:
			$AnimationPlayer.play("open")
