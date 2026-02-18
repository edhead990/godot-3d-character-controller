extends CharacterBody3D

@export var camera_controller = Node3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var previous_direction: Vector3 = Vector3.ZERO

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_controller.rotation.y).normalized()

	if camera_controller.is_resetting:
		direction = Vector3.ZERO

	var valid_x_direction = abs(previous_direction.x - direction.x) < 1.5
	var valid_z_direction = abs(previous_direction.z - direction.z) < 1.5

	if direction and valid_x_direction and valid_z_direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		# Smooth rotation in the movement direction
		# rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), 12.0 * delta)
		# Alternative: Instant rotation
		rotation.y = atan2(-velocity.x, -velocity.z)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	previous_direction = direction

	move_and_slide()
