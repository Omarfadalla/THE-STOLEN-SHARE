extends Node3D

var times_rung = 0 
@export var door :Node3D
func ring_bell():
	if $AnimationPlayer.current_animation != "press" and times_rung < 2 :
		times_rung += 1
		$AnimationPlayer.play("press")
		door.locked = false
	
