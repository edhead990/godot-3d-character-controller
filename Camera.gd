extends Node3D

@export var player: CharacterBody3D

const SPEED = 5.0
const MOUSE_X_SENSITIVITY = 0.5
const MOUSE_Y_SENSITIVITY = 0.25

var y_offset

# Called when the node enters the scene tree for the first time.
func _ready():
	y_offset = global_position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += deg_to_rad(-event.relative.x * MOUSE_X_SENSITIVITY)
		rotation.x += deg_to_rad(-event.relative.y * MOUSE_Y_SENSITIVITY)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x = player.global_position.x
	global_position.y = player.global_position.y + y_offset
	global_position.z = player.global_position.z

	# Handle input
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	if direction:
		rotation.y += -direction.x * (SPEED * delta)
		rotation.x += -direction.z * (SPEED * delta)
