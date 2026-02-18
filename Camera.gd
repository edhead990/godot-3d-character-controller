extends Node3D

@export var player: CharacterBody3D

const JOYSTICK_X_SESITIVITY: float = 2.5
const JOYSTICK_Y_SESITIVITY: float = 2.0
const MOUSE_X_SENSITIVITY: float = 0.25
const MOUSE_Y_SENSITIVITY: float = 0.125

var initial_position: Vector3
var initial_rotation: Vector3
var is_resetting: bool = false
var reset_to: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_position = global_position
	initial_rotation = global_rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += deg_to_rad(-event.relative.x * MOUSE_X_SENSITIVITY)
		rotation.x += deg_to_rad(-event.relative.y * MOUSE_Y_SENSITIVITY)
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(30))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x = player.global_position.x + initial_position.x
	global_position.y = player.global_position.y + initial_position.y
	global_position.z = player.global_position.z + initial_position.z

	if Input.is_action_just_pressed("camera_reset"):
		reset_to = Vector2(initial_rotation.x, player.rotation.y)
		is_resetting = true

	if is_resetting:
		if abs(rotation.x - reset_to.x) <= 0.001 and abs(rotation.y - reset_to.y) <= 0.001:
			is_resetting = false
		else:
			rotation.x = lerp_angle(rotation.x, reset_to.x, 20 * delta)
			rotation.y = lerp_angle(rotation.y, reset_to.y, 20 * delta)
	else:
		# Handle input
		var input_dir = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		var direction = Vector3(input_dir.x, 0, input_dir.y)
		if direction:
			rotation.y += -direction.x * (JOYSTICK_X_SESITIVITY * delta)
			rotation.x += -direction.z * (JOYSTICK_Y_SESITIVITY * delta)
			rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(30))