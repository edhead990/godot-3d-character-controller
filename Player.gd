extends CharacterBody3D

@export var camera_controller = Node3D
@export var joystick_bounce_threshold: float = 1.05

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var previous_direction: Vector3 = Vector3.ZERO
var is_rotating: bool = false
var target_y_rotation: float
var is_crouching: bool = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# Handle crouch
	if Input.is_action_just_pressed("crouch") and is_on_floor():
		is_crouching = not is_crouching

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_controller.rotation.y).normalized()

	# Ignore joystick bounce/flicks
	var valid_x_direction = abs(previous_direction.x - direction.x) < joystick_bounce_threshold
	var valid_z_direction = abs(previous_direction.z - direction.z) < joystick_bounce_threshold
	previous_direction = direction

	var speed = SPEED
	if is_crouching:
		speed = SPEED / 2

	if direction and valid_x_direction and valid_z_direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		target_y_rotation = atan2(-direction.x, -direction.z)
		is_rotating = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Smoothly rotate the player independent of the input
	if is_rotating:
		if abs(angle_difference(rotation.y, target_y_rotation)) <= 0.01:
			is_rotating = false
		else:
			rotation.y = lerp_angle(rotation.y, target_y_rotation, 0.25)

	move_and_slide()
