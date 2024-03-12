extends Camera3D

@onready var player:Player = $"../Player"

@export_category("Rotation Stuff")
@onready var initial_position_offset:Vector3 = self.position - player.position
@export var normal_look_position_offset:Vector3
@export var targeting_position_delta:Vector3
@export var targeting_look_position_offset:Vector3

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
@export var mouse_sensitivity:float = 1/100.0
@export var max_mouse_x:float = 5
@export var max_mouse_y:float = 3

@onready var debug_point_cube:Node3D = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
			# Targeting is direct rotation mode, do not update position based on mouse movement
			position = player.global_position + targeting_position_delta
		_:
			# Normal is orbit mode, update position based on mouse movement
			position = player.global_position + initial_position_offset
			position.x += sin(mouse_movement.x/max_mouse_x) * max_mouse_x
			position.y += sin(mouse_movement.y/max_mouse_y) * max_mouse_y
			# position.z += -cos(max(mouse_movement.x, mouse_movement.y))
	
func update_rotation():
	match(state):
		State.TARGETING:
			# Targeting is direct rotation mode, mouse controls rotation
			look_at(player.global_position + targeting_look_position_offset)
			rotate_y(sin(mouse_movement.x/max_mouse_x))
			rotate_x(sin(-mouse_movement.y/max_mouse_y)) #need to un-invert y
		_:
			# Normal is orbit mode, just look_at() player + offset
			# Mouse movement effects where the look position is
			var thing = pow(2, (2 * abs(mouse_movement.x)) - 8) #https://www.desmos.com/calculator/r6ttlyxzed
			var look_point_reversal:Vector3 = player.basis.z * Vector3(0,0,thing)
			look_at(player.global_position + normal_look_position_offset + look_point_reversal)
		
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
	event.relative.y *= -1 #invert y
	mouse_movement += (-event.relative * mouse_sensitivity)

	# Clamp accumulation
	# mouse_movement = clamp(mouse_movement, Vector2(-max_mouse_x, -max_mouse_y), Vector2(max_mouse_x, max_mouse_y))
	mouse_movement.x = clamp(mouse_movement.x, -max_mouse_x, max_mouse_x)
	mouse_movement.y = clamp(mouse_movement.y, -max_mouse_y, max_mouse_y)
