extends Camera3D

@onready var player = $"../Player"
@onready var initial_position_offset:Vector3 = self.position - player.position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	# position = player.position + initial_position_offset
	# look_at(player.position)
