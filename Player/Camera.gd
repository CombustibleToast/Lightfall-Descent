extends Camera3D

@onready var player:Player = $"../Player"
@onready var initial_position_offset:Vector3 = self.position - player.position
@export var normal_look_position_offset:Vector3
@export var targeting_position_delta:Vector3
@export var targeting_look_position_offset:Vector3
@export var position_adjustment_time:float = 0.8
@export var rotation_adjustment_time:float = 0.8

# Camera state machine
enum State {NORMAL, TARGETING}
@onready var state:State = State.NORMAL
@onready var state_just_changed = false

# FOV
@onready var initial_fov:float = self.fov
@onready var previous_fov:float = initial_fov
@export var targeting_fov:float = 40
@export var fov_change_time:float = 0.4

# Lerp Timer
@onready var time_since_last_state_change:float

# Mouse movement accumulator
@onready var mouse_movement:Vector2 = Vector2.ZERO
@export var mouse_sensitivity:float = 1
@export var max_mouse_x:float = 1000
@export var max_mouse_y:float = 900

@onready var debug_point_cube:Node3D = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_state_change()
	update_timer(delta)
	update_position()
	update_rotation()
	update_fov()

	state_just_changed = false

func check_state_change():
	var previous_state = state
	match(player.state):
		Player.State.ARMING:
			state = State.TARGETING
		Player.State.FIRING:
			state = State.TARGETING
		_:
			state = State.NORMAL
	
	if state != previous_state:
		state_just_changed = true


func update_timer(delta):
	# Restart timer if necessary
	if state_just_changed:
		time_since_last_state_change = 0
		return
	
	# Count timer up
	time_since_last_state_change += delta

func update_position():
	match(state):
		State.TARGETING:
			position = player.global_position + targeting_position_delta
		_:
			position = player.global_position + initial_position_offset
	

func update_rotation():
	match(state):
		State.TARGETING:
			look_at(player.global_position + targeting_look_position_offset)
		_:
			look_at(player.global_position + normal_look_position_offset)
		

func update_fov():
	if state_just_changed:
		previous_fov = fov

	var lerp_t = smoothstep(0, 1, time_since_last_state_change/fov_change_time)

	match(state):
		State.TARGETING:
			fov = lerp(previous_fov, targeting_fov, lerp_t)
		_:
			fov = lerp(previous_fov, initial_fov, lerp_t)

# Capture mouse movement
func _input(event):
	if not event is InputEventMouseMotion:
		return
	
	# https://docs.godotengine.org/en/stable/classes/class_inputeventmousemotion.html
	# Accumulate movement
	mouse_movement += (event.relative * mouse_sensitivity)

	# Clamp accumulation
	mouse_movement = clamp(mouse_movement, Vector2(-max_mouse_x, -max_mouse_y), Vector2(max_mouse_x, max_mouse_y))
