extends Control

@onready var safe_anim = get_tree().current_scene.get_node("safe/AnimationPlayer")
@onready var dial = $MainPanel/DialArea/Dial
@onready var code_paper = get_tree().current_scene.get_node("code_paper")

var rng = RandomNumberGenerator.new()

var safe_password : String = ""
var entered_code : String = ""
var safe_interactable : bool = true
var safe_busy : bool = false
var wrong_attempts : int = 0
var slot_labels : Array = []

const CODE_LENGTH := 5
const GLITCH_CHARS := "!@#$%&*?/\\|<>01"



func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 1.0
	$MainPanel.pivot_offset = $MainPanel.size / 2.0

	rng.randomize()
	safe_password = ""
	for i in CODE_LENGTH:
		safe_password += str(rng.randi_range(0, 9))
	print("SAFE CODE (debug): ", safe_password)
	
	code_paper.get_node("code_text").mesh.text = safe_password
	
	_setup_scanlines()
	_setup_vignette()
	_style_buttons()
	_build_slots()
	_update_display()
	_start_flicker()

	dial.digit_locked.connect(_on_digit_locked)
	$MainPanel/DialArea/ArrowLeft.pressed.connect(func():
		if not safe_busy: dial.nudge(-1))
	$MainPanel/DialArea/ArrowRight.pressed.connect(func():
		if not safe_busy: dial.nudge(1))
	$MainPanel/DialArea/LockButton.pressed.connect(func():
		if not safe_busy: dial.lock_in())


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and not safe_busy:
		exit_safe()
	elif event.is_action_pressed("ui_left") and not safe_busy:
		dial.nudge(-1)
	elif event.is_action_pressed("ui_right") and not safe_busy:
		dial.nudge(1)
	elif event.is_action_pressed("ui_accept") and not safe_busy:
		dial.lock_in()


# ---------- Shader-driven atmosphere ----------

func _setup_scanlines() -> void:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float line_density : hint_range(50.0, 800.0) = 260.0;
uniform float line_opacity : hint_range(0.0, 1.0) = 0.05;
void fragment() {
	float scan = sin(UV.y * line_density) * 0.5 + 0.5;
	COLOR = vec4(0.0, 0.0, 0.0, scan * line_opacity);
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	$ScanlineOverlay.material = mat

func _setup_vignette() -> void:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 1.4;
	float vig = clamp(dist - 0.25, 0.0, 1.0);
	COLOR = vec4(0.45, 0.02, 0.02, vig * intensity);
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("intensity", 0.0)
	$DangerVignette.material = mat

func _update_vignette() -> void:
	var intensity = min(wrong_attempts * 0.12, 0.6)
	var mat = $DangerVignette.material
	var t = create_tween()
	t.tween_method(func(v): mat.set_shader_parameter("intensity", v),
		mat.get_shader_parameter("intensity"), intensity, 0.3)


# ---------- Button styling (rounded, matches game palette) ----------

func _style_arrow(btn: Button, glyph: String) -> void:
	btn.text = glyph
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.35, 0.3))

	var n = StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.12, 0.14, 1)
	n.border_color = Color(0.4, 0.15, 0.15, 1)
	n.set_border_width_all(1)
	n.set_corner_radius_all(17)
	btn.add_theme_stylebox_override("normal", n)

	var h = n.duplicate()
	h.bg_color = Color(0.18, 0.12, 0.12, 1)
	h.border_color = Color(0.7, 0.2, 0.2, 1)
	btn.add_theme_stylebox_override("hover", h)

	var p = n.duplicate()
	p.bg_color = Color(0.22, 0.1, 0.1, 1)
	btn.add_theme_stylebox_override("pressed", p)

func _style_lock(btn: Button) -> void:
	btn.text = "LOCK IN"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 1.0, 0.75))

	var n = StyleBoxFlat.new()
	n.bg_color = Color(0.13, 0.13, 0.15, 1)
	n.border_color = Color(0.32, 0.32, 0.35, 1)
	n.set_border_width_all(1)
	n.set_corner_radius_all(24)
	btn.add_theme_stylebox_override("normal", n)

	var h = n.duplicate()
	h.bg_color = Color(0.19, 0.19, 0.21, 1)
	h.border_color = Color(0.5, 0.5, 0.54, 1)
	btn.add_theme_stylebox_override("hover", h)

	var p = n.duplicate()
	p.bg_color = Color(0.2, 0.28, 0.22, 1)
	p.border_color = Color(0.5, 0.85, 0.55, 1)
	btn.add_theme_stylebox_override("pressed", p)

func _style_buttons() -> void:
	_style_arrow($MainPanel/DialArea/ArrowLeft, " > ")
	_style_arrow($MainPanel/DialArea/ArrowRight, " > ")
	_style_lock($MainPanel/DialArea/LockButton)


# ---------- Progress slots ----------

func _build_slots() -> void:
	var row : HBoxContainer = $MainPanel/SlotRow
	row.add_theme_constant_override("separation", 14)
	for i in CODE_LENGTH:
		var lbl := Label.new()
		lbl.text = "–"
		lbl.custom_minimum_size = Vector2(28, 40)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.42))
		lbl.pivot_offset = Vector2(14, 20)
		row.add_child(lbl)
		slot_labels.append(lbl)

func _update_display() -> void:
	for i in CODE_LENGTH:
		if i < entered_code.length():
			slot_labels[i].text = entered_code[i]
			slot_labels[i].add_theme_color_override("font_color", Color(0.95, 0.95, 0.96))
		else:
			slot_labels[i].text = "–"
			slot_labels[i].add_theme_color_override("font_color", Color(0.4, 0.4, 0.42))

func _pop_slot(idx: int) -> void:
	var lbl = slot_labels[idx]
	lbl.scale = Vector2(1.6, 1.6)
	var t = create_tween()
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "scale", Vector2.ONE, 0.2)


# ---------- Dial → code assembly ----------

func _on_digit_locked(value: int) -> void:
	if safe_busy or entered_code.length() >= CODE_LENGTH:
		return
	var idx = entered_code.length()
	entered_code += str(value)
	_update_display()
	_pop_slot(idx)
	dial.reset_spin()
	if entered_code.length() == CODE_LENGTH:
		await get_tree().create_timer(0.25).timeout
		_check_code()


# ---------- Result handling ----------

func _check_code() -> void:
	safe_busy = true
	if entered_code == safe_password:
		_success_sequence()
	else:
		wrong_attempts += 1
		_update_vignette()
		_failure_sequence()

func _success_sequence() -> void:
	_flash(Color(0.25, 1.0, 0.4), 0.5)
	$MainPanel/SparkBurst.restart()
	$MainPanel/SparkBurst.emitting = true
	await _flicker_fade("ACCESS GRANTED", Color(0.35, 1.0, 0.45))
	await get_tree().create_timer(0.4).timeout
	safe_anim.play("open")
	safe_interactable = false
	exit_safe()

func _failure_sequence() -> void:
	_flash(Color(1.0, 0.15, 0.15), 0.55)
	_shake_panel()
	await _flicker_fade("ACCESS DENIED", Color(1.0, 0.25, 0.25))
	await _glitch_scramble()
	entered_code = ""
	_update_display()
	safe_busy = false

func _flash(color: Color, peak_alpha: float) -> void:
	var overlay = $FlashOverlay
	overlay.color = color
	overlay.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(overlay, "modulate:a", peak_alpha, 0.06)
	t.tween_property(overlay, "modulate:a", 0.0, 0.4)

func _flicker_fade(text: String, color: Color) -> void:
	var s = $MainPanel/StatusLabel
	s.text = text
	s.add_theme_color_override("font_color", color)
	s.modulate.a = 0.0
	var t = create_tween()
	var pattern = [0.0, 0.7, 0.15, 0.9, 0.3, 1.0]
	for v in pattern:
		t.tween_property(s, "modulate:a", v, 0.045)
	t.tween_interval(0.65)
	t.tween_property(s, "modulate:a", 0.0, 0.55)
	await t.finished

func _shake_panel() -> void:
	var panel = $MainPanel
	var origin = panel.position
	var magnitude = min(10 + wrong_attempts * 3, 26)
	var t = create_tween()
	for i in 5:
		var off = magnitude if i % 2 == 0 else -magnitude
		t.tween_property(panel, "position:x", origin.x + off, 0.04)
	t.tween_property(panel, "position:x", origin.x, 0.04)

func _glitch_scramble() -> void:
	var iterations = min(5 + wrong_attempts, 10)
	for i in iterations:
		for lbl in slot_labels:
			lbl.text = GLITCH_CHARS[rng.randi_range(0, GLITCH_CHARS.length() - 1)]
			lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		await get_tree().create_timer(0.035).timeout


# ---------- Ambient horror flicker ----------

func _start_flicker() -> void:
	var title = $MainPanel/Title
	while true:
		await get_tree().create_timer(rng.randf_range(1.5, 4.0)).timeout
		if not visible:
			continue
		var t = create_tween()
		t.tween_property(title, "modulate:a", rng.randf_range(0.4, 0.65), 0.03)
		t.tween_property(title, "modulate:a", 1.0, 0.06)


# ---------- Public API (called from player_interact.gd) ----------

func open_safe_password() -> void:
	if not safe_interactable:
		return
	entered_code = ""
	safe_busy = false
	$MainPanel/StatusLabel.modulate.a = 0.0
	_update_display()
	dial.reset_to_zero()

	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	$MainPanel.scale = Vector2(1.0, 0.02)
	var t = create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property($MainPanel, "scale", Vector2.ONE, 0.22)

func exit_safe() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
