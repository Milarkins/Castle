extends Camera2D

@export_node_path var target_path
@onready var target = get_node(target_path)

func _physics_process(delta):
	global_position = lerp(global_position, target.global_position, 0.1)
