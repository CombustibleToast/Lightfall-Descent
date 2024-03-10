extends Node3D
class_name TargetingReticle

@export var camera:Camera3D
@onready var stuck_on_target:bool = false
@onready var ms_elapsed:int = 0

func _process(delta):
	# Pulse and rotate if active.
	if visible:
		pulse_and_rotate(delta)
		
func pulse_and_rotate(delta):
	#TODO: Fix bug where the rotation is wonky once the object's transform is inherited
	
	# Accellerate if stuck in target
	delta *= 5 if stuck_on_target else 1

	# Rotate
	rotate_y(delta);

	# Scale to camera distance
	var distance_to_camera = (global_position - camera.position).length_squared()
	var target_scale = Vector3.ONE * log(distance_to_camera) / 2

	# Scale pulse
	ms_elapsed += delta*1000 # will overflow at some point, oh well
	scale = target_scale * (sin(ms_elapsed/500.0)/2 + 1)

# Called by Player.gd when the player has a lock on a target
func activate(point:Vector3, normal:Vector3):
	visible = true
	look_at_from_position(point, point + normal)

# Called by Player.gd when lock is lost
# Called by Rocket.gd when the rocket hits the target
func deactivate():
	visible = false

	# Inherit global transform if necessary
	if get_parent() != get_tree().root:
		var root_node = get_tree().root
		self.get_parent().remove_child(self)
		root_node.add_child(self)

	# Note unstick self
	stuck_on_target = false

func rocket_firing(target_object:Node3D):
	# The the target object might not exist (The player was not aiming at a target)
	# In that case, deactivate
	if not target_object:
		deactivate()
		return

	# Otherwise, inherit the object's transform and stay active
	var old_global_transform = global_transform
	self.get_parent().remove_child(self)
	target_object.add_child(self)
	global_transform = old_global_transform

	# Note down that reticle is stuck to target
	stuck_on_target = true