extends RigidBody3D

class_name Enemy

# State Machine
enum EnemyState {ALIVE, DYING, DEAD}
@onready var state = EnemyState.ALIVE
@onready var big_rocket_inbound:bool = false

# Statistics
@export var base_health = 1
@onready var current_health = base_health
@export var speed:float = 10

# Dying variables
@onready var stuck_rockets = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	move_and_collide(Vector3.BACK * speed * delta)

## Damage and Death

func hit_by_rocket(rocket:Rocket):
	stuck_rockets.append(rocket)

	# Wait for a big rocket if this one is not
	# This value is used in Rocket.gd to check whether or not to send in a big rocket
	if not rocket.is_big_rocket:
		big_rocket_inbound = true

	# Stop waiting if hit by a big rocket
	else:
		big_rocket_inbound = false


func take_damage(damage):
	current_health -= damage;
	if current_health <= 0:
		# Die
		# Play death animation or whatever here

		# Delete self
		self.queue_free()

## Collisions

func _on_area_3d_area_entered(area:Area3D):
	return
	print("%s was areaEntered by %s's %s"%[name, area.get_parent().name, area.name])
	if area.get_parent() && area.get_parent().is_in_group("rockets"):
		hit_by_rocket(area.get_parent())
	

func _on_body_entered(body:Node):
	print("%s was physicsBodyEntered by %s"%[name, body.name])

