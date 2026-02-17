extends Node3D

@export var player: CharacterBody3D
@export var reset_speed: float = 10.0 # Adjust for "snappiness"

const SPEED = 5.0
const MOUSE_X_SENSITIVITY = 0.5
const MOUSE_Y_SENSITIVITY = 0.25

var is_resetting: bool = false
var target_rotation_y: float = 0.0
var y_offset

# Called when the node enters the scene tree for the first time.
func _ready():
	y_offset = global_position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += deg_to_rad(-event.relative.x * MOUSE_X_SENSITIVITY)
		rotation.x += deg_to_rad(-event.relative.y * MOUSE_Y_SENSITIVITY)
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(30))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x = player.global_position.x
	global_position.y = player.global_position.y + y_offset
	global_position.z = player.global_position.z

	# Handle direction input
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	if direction:
		rotation.y += -direction.x * (SPEED * delta)
		rotation.x += -direction.z * (SPEED * delta)
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(30))

	if Input.is_action_just_pressed("camera_reset"):
		start_camera_reset(player.rotation.y)
	if is_resetting:
		_perform_reset_step(delta)

func start_camera_reset(goal_angle: float):
	target_rotation_y = goal_angle
	is_resetting = true

func _perform_reset_step(delta):
	rotation.y = lerp_angle(rotation.y, target_rotation_y, reset_speed * delta)
	rotation.x = lerp_angle(rotation.x, 0.0, reset_speed * delta)
	
	# Stop processing once we are close enough to the target
	if abs(angle_difference(rotation.y, target_rotation_y)) < 0.01:
		is_resetting = false

	# TODO: Break reset if the player tries to look around manually?
