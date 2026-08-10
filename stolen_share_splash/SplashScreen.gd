extends Control
## ============================================================
##  THE STOLEN SHARE — Horror Splash / Loading Screen
## ============================================================

@export var next_scene_path: String = "res://Levels/level_new.tscn"
@export var min_display_time: float = 6.5  
@export var custom_ui_font: Font           

@onready var bg: TextureRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var flicker_overlay: ColorRect = $FlickerOverlay
@onready var bottom_panel: VBoxContainer = $BottomPanel
@onready var loading_label: Label = $BottomPanel/LoadingLabel
@onready var progress_bar: ProgressBar = $BottomPanel/ProgressBar
@onready var percent_label: Label = $BottomPanel/PercentLabel
@onready var hint_label: Label = $BottomPanel/HintLabel
@onready var fade_rect: ColorRect = $FadeOut

var loading_messages := [
	"Sharpening the blades...",
	"Counting the stolen shares...",
	"Waking the forest...",
	"Hiding the bodies...",
	"Settling old debts...",
	"Listening for footsteps...",
	"Sealing the vault...",
	"The key remembers...",
	"Following the bloody trail...",
]

var hints := [
	"Tip: Not everyone in the woods is who they claim to be.",
	"Tip: Blood dries faster than secrets.",
	"Tip: Every share has a price.",
	"Tip: The key opens more than doors.",
]

var _elapsed := 0.0
var _display_progress := 0.0
var _thread_started := false
var _load_finished := false
var _finishing := false

func _ready() -> void:
	randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepare_initial_state()
	await get_tree().process_frame
	bg.pivot_offset = bg.size / 2.0
	
	loading_label.pivot_offset = loading_label.size / 2.0
	percent_label.pivot_offset = percent_label.size / 2.0
	
	_play_intro()
	_start_background_drift()
	_start_flicker_loop()
	_start_loading()
	_rotate_messages_loop()

# ---------------------------------------------------------------
# Setup
# ---------------------------------------------------------------
func _prepare_initial_state() -> void:
	if custom_ui_font:
		loading_label.add_theme_font_override("font", custom_ui_font)
		percent_label.add_theme_font_override("font", custom_ui_font)
		hint_label.add_theme_font_override("font", custom_ui_font)

	# Larger, prominent font sizing
	loading_label.add_theme_font_size_override("font_size", 38)
	percent_label.add_theme_font_size_override("font_size", 34)
	hint_label.add_theme_font_size_override("font_size", 24)

	bg.modulate.a = 0.0
	bg.scale = Vector2(1.12, 1.12)
	vignette.modulate.a = 0.0
	vignette.color = Color(0.2, 0.22, 0.25) # Cold, greyish outer tone
	flicker_overlay.visible = false         # Disable full-screen harsh flash
	bottom_panel.modulate.a = 0.0
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.value = 0
	percent_label.text = "0%"
	hint_label.text = hints.pick_random()

# ---------------------------------------------------------------
# Intro animation
# ---------------------------------------------------------------
func _play_intro() -> void:
	var t := create_tween()
	t.tween_property(bg, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(vignette, "modulate:a", 0.85, 3.5)

	var t2 := create_tween()
	t2.tween_interval(2.5)
	t2.tween_property(bottom_panel, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)

func _start_background_drift() -> void:
	var t := create_tween()
	t.set_loops()
	t.tween_property(bg, "scale", Vector2(1.18, 1.18), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(bg, "scale", Vector2(1.12, 1.12), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_flicker_loop() -> void:
	# Smooth, greyish breathing confined strictly to the outer vignette border
	var t := create_tween()
	t.set_loops()
	t.tween_property(vignette, "modulate:a", randf_range(0.7, 0.82), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(vignette, "modulate:a", randf_range(0.85, 0.95), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_schedule_harsh_flicker()

func _schedule_harsh_flicker() -> void:
	await get_tree().create_timer(randf_range(6.0, 12.0)).timeout
	if not is_inside_tree():
		return
		
	# Slow, rolling greyish outer wave instead of a full-screen flash
	var t := create_tween()
	t.tween_property(vignette, "modulate:a", 0.98, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(vignette, "modulate:a", 0.75, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	_schedule_harsh_flicker()

# ---------------------------------------------------------------
# Loading message rotation
# ---------------------------------------------------------------
func _rotate_messages_loop() -> void:
	await get_tree().create_timer(2.0).timeout
	loading_label.text = loading_messages.pick_random()
	loading_label.modulate.a = 0.0
	var intro_t := create_tween()
	intro_t.tween_property(loading_label, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)

	while not _finishing:
		await get_tree().create_timer(4.0).timeout
		if _finishing:
			break
		var msg: String = loading_messages.pick_random()
		await _swap_label_text(loading_label, msg)

func _swap_label_text(label: Label, new_text: String) -> void:
	var out_t := create_tween()
	out_t.parallel().tween_property(label, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	out_t.parallel().tween_property(label, "scale", Vector2(1.05, 1.05), 1.5).set_trans(Tween.TRANS_SINE)
	await out_t.finished
	
	label.text = new_text
	label.scale = Vector2(0.95, 0.95)
	
	var in_t := create_tween()
	in_t.parallel().tween_property(label, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	in_t.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await in_t.finished

# ---------------------------------------------------------------
# Actual (or simulated) loading
# ---------------------------------------------------------------
func _start_loading() -> void:
	if ResourceLoader.exists(next_scene_path):
		var err := ResourceLoader.load_threaded_request(next_scene_path)
		_thread_started = (err == OK)
	if not _thread_started:
		push_warning("SplashScreen: '%s' not found — simulating the load bar only." % next_scene_path)

func _process(delta: float) -> void:
	_elapsed += delta

	var real_progress := 0.0
	if _thread_started:
		var progress_arr: Array = []
		var status := ResourceLoader.load_threaded_get_status(next_scene_path, progress_arr)
		if progress_arr.size() > 0:
			real_progress = progress_arr[0]
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			real_progress = 1.0
			_load_finished = true
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_load_finished = true
			real_progress = 1.0
	else:
		real_progress = clamp(_elapsed / min_display_time, 0.0, 1.0)
		if real_progress >= 1.0:
			_load_finished = true

	var momentum: float = max(0.1, pow(_display_progress, 2.0) * 8.0)
	_display_progress = lerp(_display_progress, real_progress, delta * momentum)
	
	if real_progress >= 1.0 and _display_progress > 0.99:
		_display_progress = 1.0

	progress_bar.value = _display_progress * 100.0
	percent_label.text = "%d%%" % int(round(_display_progress * 100.0))
	
	var target_color = Color.WHITE.lerp(Color(0.6, 0.1, 0.1), _display_progress)
	progress_bar.modulate = target_color
	percent_label.modulate = target_color

	if _load_finished and _elapsed >= min_display_time and _display_progress >= 0.999 and not _finishing:
		_finishing = true
		set_process(false)
		_finish_loading()

# ---------------------------------------------------------------
# Outro
# ---------------------------------------------------------------
func _finish_loading() -> void:
	await _swap_label_text(loading_label, "The door is open...")
	await get_tree().create_timer(1.0).timeout
	_fade_out_and_switch()

func _fade_out_and_switch() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_switch_scene)

func _switch_scene() -> void:
	if _thread_started:
		var result = ResourceLoader.load_threaded_get(next_scene_path)
		if result:
			get_tree().change_scene_to_packed(result)
			return
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
