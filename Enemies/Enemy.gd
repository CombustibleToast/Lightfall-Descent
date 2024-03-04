extends RigidBody3D

class_name Enemy

# State Machine
enum EnemyState {ALIVE, DYING, DEAD}
@onready var state = EnemyState.ALIVE

# Dying variables
@export var death_time_after_hit = 2
@onready var remaining_time_until_death = death_time_after_hit
@onready var stuck_rockets = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == EnemyState.DYING:
		elapse_death_timer_and_die(delta)

## Damage and Death

func hit_by_rocket(rocket:Rocket):
	state = EnemyState.DYING
	stuck_rockets.append(rocket)
	rocket.enemy_hit(self)

func elapse_death_timer_and_die(delta):
	remaining_time_until_death -= delta

	if remaining_time_until_death <= 0:
		# Here we want to play an explosion animation and sound and stuff. For now, just delete all hit rockets and self
		for rocket in stuck_rockets:
			rocket.queue_free()
		self.queue_free()

## Collisions

func _on_area_3d_area_entered(area:Area3D):
	print("%s was areaEntered by %s's %s"%[name, area.get_parent().name, area.name])
	if area.get_parent() && area.get_parent().is_in_group("rockets"):
		hit_by_rocket(area.get_parent())
	

func _on_body_entered(body:Node):
	print("%s was physicsBodyEntered by %s"%[name, body.name])

