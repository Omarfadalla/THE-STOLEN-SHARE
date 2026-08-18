extends RigidBody3D

@export var positions : Array[Node3D]
@export var door : Node3D
@export var is_pickup : bool = true

@onready var rng = RandomNumberGenerator.new()
var pos_obj
var held : bool = false

func _ready() -> void:
	add_to_group("key")
	var chance = rng.randi_range(0, positions.size() - 1)
	global_transform.origin = positions[chance].global_transform.origin
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
	freeze = true
	pos_obj = null
	held = false
	set_physics_process(false)
	for shape in get_children():
		if shape is CollisionShape3D:
			shape.disabled = true

	if door.keyhole == null:
		door.unlock()
		queue_free()
		return

	var target = door.keyhole
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target.global_position, 0.4)
	tween.tween_property(self, "global_rotation", target.global_rotation, 0.4)
	tween.set_parallel(false)
	tween.tween_property(self, "rotation:z", rotation.z + deg_to_rad(90), 0.3)
	tween.tween_callback(func():
		door.unlock()
		queue_free()
	)

func _physics_process(delta: float) -> void:
	if pos_obj != null:
		global_transform.origin = pos_obj.global_transform.origin
