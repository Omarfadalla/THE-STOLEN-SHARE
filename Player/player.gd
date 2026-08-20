extends CharacterBody3D

var SPEED = 250
const JUMP_VELOCITY = 100
var crouching :bool = false

@export var max_health: float = 100.0
var health: float

@export var walk_noise_radius: float = 5.0
@export var run_noise_radius: float = 11.0
@export var crouch_noise_radius: float = 1.5
@export var footstep_interval_walk: float = 0.5
@export var footstep_interval_crouch: float = 0.8
var footstep_timer: float = 0.0

signal died
signal health_changed(current: float, max: float)


func _ready() -> void:
	add_to_group("player")
	health = max_health


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("crouch"):
		crouching = !crouching
	if crouching and SPEED != 150:
		SPEED = 150
	if !crouching and SPEED != 250:
		SPEED = 250
	if Input.is_action_just_pressed("flashlight"):
		$Head/flashlight.visible = !$Head/flashlight.visible


func _physics_process(delta: float) -> void:

	if crouching and $CollisionShape3D.shape.height > 0.25 :
		var crouch_height = lerp($CollisionShape3D.shape.height,0.25,0.2)
		$CollisionShape3D.shape.height = crouch_height
	if !crouching and $CollisionShape3D.shape.height < 2.0 :
		var crouch_height = lerp($CollisionShape3D.shape.height,2.0,0.2)
		$CollisionShape3D.shape.height = crouch_height
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

	if direction and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_emit_footstep()
	else:
		footstep_timer = 0.0


func _emit_footstep() -> void:
	var radius := walk_noise_radius
	var interval := footstep_interval_walk
	if crouching:
		radius = crouch_noise_radius
		interval = footstep_interval_crouch
	elif SPEED > 250: 
		radius = run_noise_radius

	footstep_timer = interval
	if has_node("/root/NoiseBus"):
		get_node("/root/NoiseBus").emit_noise(global_position, radius, 1.0)


func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()
