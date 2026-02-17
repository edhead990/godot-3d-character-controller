extends CharacterBody3D

@export var camera_controller = Node3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var is_aiming = false
var is_strafing = false
var strafe_rotation: float = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle aim state
	if Input.is_action_pressed("aim"):
		is_aiming = true
	else:
		is_aiming = false
		
	# Handle strafe
	if Input.is_action_just_pressed("strafe"):
		# Set strafe angle to direction character is facing
		strafe_rotation = rotation.y
		camera_controller.start_camera_reset(rotation.y)
	if Input.is_action_pressed("strafe"):
		is_strafing = true
	else:
		is_strafing = false

	# Lock player rotation to camera
	if is_aiming:
		rotation.y = camera_controller.rotation.y

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_controller.rotation.y).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if is_strafing:
			rotation.y = strafe_rotation
		
		# Smooth rotation in the movement direction
		else:
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
