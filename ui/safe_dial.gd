extends Control

# =========================================================
# SAFE DIAL — a rotary combination-lock widget.
# The numbered Face spins as one piece (drag with the mouse,
# or call nudge()); the red Pointer stays fixed at the top.
# Call lock_in() to commit whatever digit currently sits
# under the pointer — the parent listens for "digit_locked".
# =========================================================

signal digit_locked(value: int)
signal digit_changed(value: int)

const DIGIT_COUNT := 10
const STEP := TAU / DIGIT_COUNT

var current_index := 0
var dragging := false
var drag_ref_angle := 0.0
var rotation_ref := 0.0

@onready var face: Control = $Face

func _ready() -> void:
	face.pivot_offset = face.size / 2.0
	_build_ticks_and_numbers()
	_snap_to(0, false)

func _build_ticks_and_numbers() -> void:
	var center = face.size / 2.0
	var radius = face.size.x / 2.0 - 6.0
	var minor_per_major = 4
	var total_ticks = DIGIT_COUNT * (minor_per_major + 1)

	for t in total_ticks:
		var angle = t * TAU / total_ticks - PI / 2.0
		var is_major = (t % (minor_per_major + 1) == 0)
		var tick = ColorRect.new()
		var h = 14.0 if is_major else 7.0
		var w = 3.0 if is_major else 2.0
		tick.size = Vector2(w, h)
		tick.pivot_offset = Vector2(w / 2.0, h / 2.0)
		var r = radius - h / 2.0
		var pos = center + Vector2(cos(angle), sin(angle)) * r
		tick.position = pos - tick.pivot_offset
		tick.rotation = angle + PI / 2.0
		tick.color = Color(0.88, 0.88, 0.9) if is_major else Color(0.45, 0.45, 0.48)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.add_child(tick)

	for d in DIGIT_COUNT:
		var angle = d * STEP - PI / 2.0
		var lbl = Label.new()
		lbl.text = str(d)
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.94))
		lbl.size = Vector2(26, 26)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r = radius - 24.0
		var pos = center + Vector2(cos(angle), sin(angle)) * r
		lbl.position = pos - lbl.size / 2.0
		face.add_child(lbl)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_ref_angle = _angle_to(event.position)
			rotation_ref = face.rotation
		elif dragging:
			dragging = false
			_snap_nearest()
	elif event is InputEventMouseMotion and dragging:
		var ang = _angle_to(event.position)
		face.rotation = rotation_ref + (ang - drag_ref_angle)
		emit_signal("digit_changed", _index_from_rotation(face.rotation))

func _angle_to(local_pos: Vector2) -> float:
	var center = size / 2.0
	return (local_pos - center).angle()

func _index_from_rotation(rot: float) -> int:
	var idx = int(round(-rot / STEP))
	return ((idx % DIGIT_COUNT) + DIGIT_COUNT) % DIGIT_COUNT

func _snap_nearest() -> void:
	_snap_to(_index_from_rotation(face.rotation), true)

func _snap_to(idx: int, animate: bool) -> void:
	current_index = ((idx % DIGIT_COUNT) + DIGIT_COUNT) % DIGIT_COUNT
	var target = -current_index * STEP
	if animate:
		var t = create_tween()
		t.set_trans(Tween.TRANS_BACK)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(face, "rotation", target, 0.32)
	else:
		face.rotation = target
	emit_signal("digit_changed", current_index)

func nudge(dir: int) -> void:
	_snap_to(current_index + dir, true)

func lock_in() -> void:
	emit_signal("digit_locked", current_index)

func reset_spin() -> void:
	var start = face.rotation
	var t = create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(face, "rotation", start - TAU, 0.4)
	t.tween_property(face, "rotation", 0.0, 0.3)
	t.tween_callback(func():
		face.rotation = 0.0
		current_index = 0
	)

func reset_to_zero() -> void:
	face.rotation = 0.0
	current_index = 0
