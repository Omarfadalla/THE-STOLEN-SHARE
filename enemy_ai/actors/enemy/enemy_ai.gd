extends CharacterBody3D
class_name HorrorEnemy

enum State { IDLE, PATROL, SUSPICIOUS, INVESTIGATE, CHASE, SEARCH, ATTACK }

@export_group("Movement")
@export var patrol_speed: float = 2.0
@export var investigate_speed: float = 2.6
@export var chase_speed: float = 4.6
@export var rotation_speed: float = 6.0
@export var waypoint_tolerance: float = 1.5 

@export_group("Vision")
@export var vision_range: float = 14.0
@export var vision_angle_deg: float = 55.0      
@export var vision_close_range: float = 2.5     
@export var eye_height: float = 1.6
@export var vision_check_interval: float = 0.15 

@export_group("Hearing")
@export var hearing_range: float = 11.0

@export_group("Suspicion")
@export var suspicion_gain_per_sec: float = 55.0   
@export var suspicion_decay_per_sec: float = 20.0
@export var chase_threshold: float = 100.0
@export var investigate_threshold: float = 35.0
@export var noise_suspicion_flat: float = 40.0

@export_group("Combat")
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.2
@export var attack_damage: float = 25.0

@export_group("Search")
@export var search_point_count: int = 4
@export var search_radius: float = 6.0
@export var search_wait_time: float = 2.0
@export var memory_duration: float = 9.0 

@export_group("Patrol")
@export var patrol_points_path: NodePath   
@export var patrol_wait_time: float = 2.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_timer: Timer = $AttackTimer
@onready var patrol_wait_timer: Timer = $PatrolWaitTimer
@onready var search_wait_timer: Timer = $SearchWaitTimer
@onready var vision_check_timer: Timer = $VisionCheckTimer
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var eyes: Node3D = $Eyes

var state: State = State.IDLE
var player: Node3D = null

var suspicion: float = 0.0
var last_known_player_pos: Vector3 = Vector3.ZERO
var has_last_known_pos: bool = false
var time_since_seen: float = 0.0

var patrol_points: Array[Vector3] = []
var patrol_index: int = 0
var patrol_waiting: bool = false

var search_points: Array[Vector3] = []
var search_index: int = 0
var search_waiting: bool = false

var can_attack: bool = true
var can_see_player_now: bool = false
var safe_velocity: Vector3 = Vector3.ZERO

var _nav_map: RID = RID()


func _ready() -> void:
	add_to_group("enemies")

	nav_agent.velocity_computed.connect(_on_velocity_computed)

	if patrol_points_path != NodePath(""):
		var container := get_node_or_null(patrol_points_path)
		if container:
			for child in container.get_children():
				if child is Node3D:
					patrol_points.append(child.global_position)

	player = get_tree().get_first_node_in_group("player")

	if has_node("/root/NoiseBus"):
		var bus := get_node("/root/NoiseBus")
		bus.noise_emitted.connect(_on_noise_emitted)

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)

	patrol_wait_timer.one_shot = true
	patrol_wait_timer.timeout.connect(func(): patrol_waiting = false)

	search_wait_timer.one_shot = true
	search_wait_timer.timeout.connect(_advance_search_point)

	vision_check_timer.wait_time = vision_check_interval
	vision_check_timer.timeout.connect(_update_vision)
	vision_check_timer.start()

	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5

	# Cache the map RID immediately, but DON'T query it yet
	_nav_map = get_world_3d().navigation_map

	_change_state(State.PATROL if patrol_points.size() > 0 else State.IDLE)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	time_since_seen += delta
	_update_suspicion(delta)
	_evaluate_state_transitions()

	match state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.CHASE:
			_process_chase(delta)
		State.SEARCH:
			_process_search(delta)
		State.ATTACK:
			_process_attack(delta)

	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


func _update_vision() -> void:
	can_see_player_now = false
	if not player:
		return

	var eye_pos: Vector3 = eyes.global_position
	var to_player: Vector3 = player.global_position - eye_pos
	var dist: float = to_player.length()

	if dist > vision_range:
		return

	var within_close_range := dist <= vision_close_range
	var within_cone := true
	if not within_close_range:
		var facing: Vector3 = -global_transform.basis.z
		var angle_deg: float = rad_to_deg(facing.angle_to(to_player.normalized()))
		within_cone = angle_deg <= vision_angle_deg

	if not (within_close_range or within_cone):
		return

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(eye_pos, player.global_position + Vector3.UP * 0.5)
	query.exclude = [self]
	query.collision_mask = 0xFFFFFFFF
	var result := space_state.intersect_ray(query)

	if result.is_empty() or result.collider == player or result.collider.is_ancestor_of(player):
		can_see_player_now = true
		last_known_player_pos = player.global_position
		has_last_known_pos = true
		time_since_seen = 0.0


func _update_suspicion(delta: float) -> void:
	if can_see_player_now:
		var dist: float = global_position.distance_to(player.global_position)
		var falloff: float = clamp(1.0 - (dist / vision_range), 0.15, 1.0)
		suspicion = min(suspicion + suspicion_gain_per_sec * falloff * delta, chase_threshold)
	else:
		suspicion = max(suspicion - suspicion_decay_per_sec * delta, 0.0)


func _on_noise_emitted(pos: Vector3, radius: float, loudness: float) -> void:
	if state == State.CHASE or state == State.ATTACK:
		return
	var dist := global_position.distance_to(pos)
	var effective_range: float = max(hearing_range, radius) * loudness
	if dist <= effective_range:
		suspicion = min(suspicion + noise_suspicion_flat * loudness, chase_threshold)
		last_known_player_pos = pos
		has_last_known_pos = true
		time_since_seen = 0.0
		if state == State.IDLE or state == State.PATROL:
			_change_state(State.INVESTIGATE)


func _evaluate_state_transitions() -> void:
	if state == State.ATTACK:
		return

	if suspicion >= chase_threshold:
		if state != State.CHASE:
			_change_state(State.CHASE)
		return

	if state == State.CHASE:
		if time_since_seen > memory_duration:
			_change_state(State.SEARCH)
		return

	if suspicion >= investigate_threshold and state in [State.IDLE, State.PATROL, State.SUSPICIOUS]:
		_change_state(State.SUSPICIOUS)
		return

	if state == State.SUSPICIOUS and suspicion < investigate_threshold * 0.5 and not can_see_player_now:
		_change_state(State.PATROL if patrol_points.size() > 0 else State.IDLE)


func _change_state(new_state: State) -> void:
	state = new_state

	match new_state:
		State.INVESTIGATE:
			_set_nav_target(last_known_player_pos)
		State.SEARCH:
			_generate_search_points()
			search_index = 0
			search_waiting = false
			if search_points.size() > 0:
				_set_nav_target(search_points[0])
		State.PATROL:
			if patrol_points.size() > 0:
				_set_nav_target(patrol_points[patrol_index])


func _process_idle(_delta: float) -> void:
	_stop_movement()


func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_change_state(State.IDLE)
		return

	if patrol_waiting:
		_stop_movement()
		return

	var target_pos_2d := Vector2(nav_agent.target_position.x, nav_agent.target_position.z)
	var current_pos_2d := Vector2(global_position.x, global_position.z)
	var dist_to_target := current_pos_2d.distance_to(target_pos_2d)

	if dist_to_target <= waypoint_tolerance:
		patrol_waiting = true
		patrol_wait_timer.wait_time = patrol_wait_time
		patrol_wait_timer.start()
		patrol_index = (patrol_index + 1) % patrol_points.size()
		if patrol_points.size() > 1:
			_set_nav_target(patrol_points[patrol_index])
		else:
			_stop_movement()
		return

	if _move_toward_target(patrol_speed, delta):
		patrol_waiting = true
		patrol_wait_timer.wait_time = patrol_wait_time
		patrol_wait_timer.start()
		patrol_index = (patrol_index + 1) % patrol_points.size()
		if patrol_points.size() > 1:
			_set_nav_target(patrol_points[patrol_index])


func _process_suspicious(delta: float) -> void:
	_stop_movement()
	var look_target: Vector3 = player.global_position if can_see_player_now else last_known_player_pos
	_face_toward(look_target, delta)


func _process_investigate(delta: float) -> void:
	if _move_toward_target(investigate_speed, delta):
		_change_state(State.SEARCH)


func _process_chase(delta: float) -> void:
	if not player:
		return

	var target_pos: Vector3 = player.global_position if can_see_player_now else last_known_player_pos
	
	if nav_agent.target_position.distance_to(target_pos) > 0.5:
		_set_nav_target(target_pos)

	_move_toward_target(chase_speed, delta)

	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_range and can_see_player_now:
		_change_state(State.ATTACK)


func _process_search(delta: float) -> void:
	if search_points.is_empty():
		_change_state(State.PATROL if patrol_points.size() > 0 else State.IDLE)
		return

	if search_waiting:
		_stop_movement()
		return

	if _move_toward_target(investigate_speed * 0.9, delta):
		search_waiting = true
		search_wait_timer.wait_time = search_wait_time
		search_wait_timer.start()


func _process_attack(_delta: float) -> void:
	_stop_movement()
	if not player:
		_change_state(State.SEARCH)
		return

	_face_toward(player.global_position, 0.3)

	var dist := global_position.distance_to(player.global_position)
	if dist > attack_range * 1.3:
		_change_state(State.CHASE)
		return

	if can_attack:
		can_attack = false
		attack_timer.start()
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)


# ---------------------------------------------------------------------------
# NAVIGATION HELPERS
# ---------------------------------------------------------------------------

## Returns true only when the NavigationServer has finished its first sync.
func _nav_map_ready() -> bool:
	return _nav_map.is_valid() and NavigationServer3D.map_get_iteration_id(_nav_map) > 0


## Sets the agent target. If the nav server isn't synced yet, uses raw position.
## Once synced, snaps to the nearest point on the navmesh surface.
func _set_nav_target(pos: Vector3) -> void:
	if _nav_map_ready():
		var snapped := NavigationServer3D.map_get_closest_point(_nav_map, pos)
		nav_agent.target_position = snapped
	else:
		nav_agent.target_position = pos


func _move_toward_target(speed: float, delta: float) -> bool:
	var current_pos_2d := Vector2(global_position.x, global_position.z)
	var target_pos_2d := Vector2(nav_agent.target_position.x, nav_agent.target_position.z)
	
	if current_pos_2d.distance_to(target_pos_2d) <= waypoint_tolerance:
		_stop_movement()
		return true

	var next_point: Vector3
	var has_valid_path: bool = false
	
	# Only trust the path if the nav server is ready AND has computed a path.
	if _nav_map_ready() and nav_agent.get_current_navigation_path().size() > 0 and not nav_agent.is_navigation_finished():
		next_point = nav_agent.get_next_path_position()
		has_valid_path = true
	else:
		next_point = nav_agent.target_position

	var direction: Vector3 = next_point - global_position
	direction.y = 0

	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		var intended_velocity: Vector3 = direction * speed
		_face_toward(global_position + direction, delta)

		if has_valid_path and nav_agent.avoidance_enabled:
			nav_agent.set_velocity(intended_velocity)
		else:
			safe_velocity = intended_velocity
	else:
		_stop_movement()

	return false


func _stop_movement() -> void:
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(Vector3.ZERO)
	else:
		safe_velocity = Vector3.ZERO


func _on_velocity_computed(calculated_safe_velocity: Vector3) -> void:
	safe_velocity = calculated_safe_velocity


func _face_toward(target: Vector3, delta: float) -> void:
	var flat_target := Vector3(target.x, global_position.y, target.z)
	if flat_target.distance_to(global_position) < 0.05:
		return

	var target_basis := Basis.looking_at(flat_target - global_position, Vector3.UP)
	var current_quat := global_transform.basis.orthonormalized().get_rotation_quaternion()
	var target_quat := target_basis.orthonormalized().get_rotation_quaternion()
	var new_quat := current_quat.slerp(target_quat, clamp(rotation_speed * delta, 0.0, 1.0))

	var scale := global_transform.basis.get_scale()
	global_transform.basis = Basis(new_quat).scaled(scale)


func _advance_search_point() -> void:
	search_waiting = false
	search_index += 1
	if search_index >= search_points.size():
		_change_state(State.PATROL if patrol_points.size() > 0 else State.IDLE)
		return
	_set_nav_target(search_points[search_index])


func _generate_search_points() -> void:
	search_points.clear()
	var origin: Vector3 = last_known_player_pos if has_last_known_pos else global_position
	var nav_map := get_world_3d().navigation_map
	for i in range(search_point_count):
		var angle: float = randf() * TAU
		var radius: float = randf_range(search_radius * 0.3, search_radius)
		var candidate: Vector3 = origin + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		# Only snap to navmesh if the server is ready; otherwise use raw candidate
		if _nav_map_ready():
			var closest: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, candidate)
			search_points.append(closest)
		else:
			search_points.append(candidate)
