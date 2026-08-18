extends RigidBody3D

@export var positions : Array[Node3D]
@export var door : Node3D
@export var is_pickup : bool = true

@onready var rng = RandomNumberGenerator.new()
@onready var mesh = $key
@onready var collision = $CollisionShape3D

var pos_obj

const WORLD_SCALE := 30.0
const WORLD_ROT_Y := 0.0
const HELD_SCALE := 2.0
const HELD_ROT_Y := -90.0


const MODEL_FIX_Y := 180.0

func _ready() -> void:
	add_to_group("key")
	var chance = rng.randi_range(0, positions.size() - 1)
	global_transform.origin = positions[chance].global_transform.origin
	rotation = Vector3(rotation.x, deg_to_rad(WORLD_ROT_Y), rotation.z)
	mesh.scale = Vector3.ONE * WORLD_SCALE
	collision.scale = Vector3.ONE * WORLD_SCALE
	freeze = true
	if not is_pickup:
		visible = false
	print(str(chance))

func hit_obj(body):
	pos_obj = body
	freeze = true
	mesh.scale = Vector3.ONE * HELD_SCALE
	collision.scale = Vector3.ONE * HELD_SCALE
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true

func insert_into_door():
	pos_obj = null
	set_physics_process(false)
	mesh.scale = Vector3.ONE * 5.0
	collision.scale = Vector3.ONE * 5.0
	for shape in get_children():
		if shape is CollisionShape3D:
			shape.disabled = true

	if door.keyhole == null:
		door.unlock()
		queue_free()
		return

	var target = door.keyhole
	var target_basis = target.global_transform.basis.orthonormalized()
	var target_quat = target_basis.get_rotation_quaternion()

	var insert_offset = (target_basis.z * -0.15) + (target_basis.x * 0.15)

	var start_quat = global_transform.basis.orthonormalized().get_rotation_quaternion()
	var start_pos = global_position

	var tween = create_tween()

	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target.global_position + insert_offset, 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t):
		var q = start_quat.slerp(target_quat, t)
		global_transform.basis = Basis(q)
	, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)

	tween.tween_interval(0.3)

	tween.tween_property(self, "global_position", target.global_position, 0.9)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(0.25)

	var turn_points = [0.0, deg_to_rad(20), deg_to_rad(35), deg_to_rad(-35)]
	var turn_durations = [0.55, 0.65, 0.8]

	for i in range(turn_durations.size()):
		var from_angle = turn_points[i]
		var to_angle = turn_points[i + 1]
		tween.tween_method(func(angle):
			var turn_quat = Quaternion(Vector3(0, 0, 1), angle)
			global_transform.basis = Basis(target_quat * turn_quat)
		, from_angle, to_angle, turn_durations[i]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(0.2)

	tween.tween_callback(func():
		door.unlock()
		queue_free()
	)
func _physics_process(delta: float) -> void:
	if pos_obj != null:
		global_transform.origin = pos_obj.global_transform.origin
		var target_basis = pos_obj.global_transform.basis.orthonormalized()
		target_basis = target_basis.rotated(target_basis.y, deg_to_rad(HELD_ROT_Y + MODEL_FIX_Y))
		global_transform.basis = global_transform.basis.orthonormalized().slerp(target_basis, 0.3)
