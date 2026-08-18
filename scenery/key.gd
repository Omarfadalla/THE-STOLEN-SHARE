extends RigidBody3D

@export var positions : Array[Node3D]
@export var door : Node3D
@export var is_pickup : bool = true

@onready var rng = RandomNumberGenerator.new()
var pos_obj

func _ready() -> void:
	add_to_group("key")
	var chance = rng.randi_range(0, positions.size() - 1)
	global_transform.origin = positions[chance].global_transform.origin
	freeze = true
	if not is_pickup:
		visible = false
	print(str(chance))

func hit_obj(body):
	pos_obj = body
	freeze = true
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true

func insert_into_door():
	pos_obj = null
	set_physics_process(false)
	for shape in get_children():
		if shape is CollisionShape3D:
			shape.disabled = true

	if door.keyhole == null:
		door.unlock()
		queue_free()
		return

	var target = door.keyhole
	var insert_offset = target.global_transform.basis.z * 0.15  # start slightly outside the hole

	var tween = create_tween()
	# Move + rotate into position just outside the keyhole
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target.global_position + insert_offset, 0.35)
	tween.tween_property(self, "global_rotation", target.global_rotation, 0.35)
	tween.set_parallel(false)

	# Slide into the hole
	tween.tween_property(self, "global_position", target.global_position, 0.25)

	# Turn like a real lock: rotate forward then back around local Z
	tween.tween_property(self, "rotation:z", rotation.z + deg_to_rad(35), 0.2)
	tween.tween_property(self, "rotation:z", rotation.z - deg_to_rad(35), 0.25)

	tween.tween_callback(func():
		door.unlock()
		queue_free()
	)

func _physics_process(delta: float) -> void:
	if pos_obj != null:
		global_transform.origin = pos_obj.global_transform.origin
		global_transform.basis = global_transform.basis.slerp(pos_obj.global_transform.basis, 0.3)
