extends Control

func _ready() -> void:
	$fade_ui/AnimationPlayer.play("fade")
	$pause_menu.visible = false
	await get_tree().create_timer(3.1 , false).timeout
	$fade_ui.visible = false

func resume_game():
	get_tree().paused = false
	$pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func quit_game():
	get_tree().quit()

func open_safe_password() -> void:
	$safe_ui.open_safe_password()

func exit_safe():
	$safe_ui.exit_safe()

func set_task(task_text : String) -> void:
	$task_ui/task_text.text = task_text

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and !$safe_ui.visible:
		$pause_menu.visible = !$pause_menu.visible
		get_tree().paused = $pause_menu.visible
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if !get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
