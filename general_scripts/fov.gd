extends Camera3D

@export var normal_fov: float = 75.0
@export var zoom_fov: float = 30.0
@export var zoom_speed: float = 12.0 # Adjust this to make zooming faster or slower

func _process(delta: float) -> void:
	# Determine target FOV based on whether the button is being held down
	var wanted_fov = zoom_fov if Input.is_action_pressed("zoom") else normal_fov
	
	# Smoothly interpolate towards the target FOV (multiplying by delta makes it frame-rate independent)
	fov = lerp(fov, wanted_fov, zoom_speed * delta)
