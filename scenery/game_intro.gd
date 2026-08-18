extends Node3D


func _ready() -> void:
	$AnimationPlayer.play("cutscene")
	await get_tree().create_timer(9.3, false).timeout
	$cutscene_ui/AnimationPlayer.play("fade")
	await get_tree().create_timer(2.0, false).timeout
	get_tree().change_scene_to_file("res://Levels/level_new.tscn")
