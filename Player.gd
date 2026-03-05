extends CharacterBody3D

@export var camera_controller = Node3D
@export var joystick_bounce_threshold: float = 1.05

@onready var view: Area3D = get_parent().get_node("CameraController/SpringArm3D/View")
@onready var line_of_site: RayCast3D = get_parent().get_node("CameraController/SpringArm3D/View/LineOfSite")

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

var is_aiming = false
var is_strafing = false
var strafe_rotation: float = 0.0
var current_target: Node3D = null

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
	# TODO: Consider adding buffer?
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# Handle aim state
	if Input.is_action_pressed("aim"):
		is_aiming = true
	else:
		is_aiming = false

	# Handle crouch
	if Input.is_action_just_pressed("crouch") and is_on_floor():
		is_crouching = not is_crouching
		
	# Handle strafe/targeting
	if Input.is_action_just_pressed("strafe"):
		current_target = get_best_target()
		if current_target == null:
			# Set strafe angle to direction character is facing
			strafe_rotation = rotation.y
			camera_controller.start_camera_reset(strafe_rotation)
	
	if Input.is_action_pressed("strafe"):
		is_strafing = true
	else:
		is_strafing = false
		current_target = null
		
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
		
	if current_target and is_instance_valid(current_target):
		# Lock on
		var look_pos = current_target.global_position
		look_pos.y = global_position.y
		# Smooth rotation toward the target
		var target_basis = transform.looking_at(look_pos).basis
		transform.basis = transform.basis.slerp(target_basis, 12.0 * delta)
		is_rotating = false
		
	elif is_strafing:
		rotation.y = strafe_rotation
		is_rotating = false
		
	elif is_rotating:
		# Smoothly rotate the player independent of the input
		if abs(angle_difference(rotation.y, target_y_rotation)) <= 0.01:
			is_rotating = false
		else:
			rotation.y = lerp_angle(rotation.y, target_y_rotation, 0.25)
		
	move_and_slide()


func get_best_target() -> Node3D:
	var enemies = view.get_overlapping_bodies()
	var best_target = null
	var highest_score = -1.0 # Dot product range -1 to 1

	line_of_site.enabled = true
	
	for enemy in enemies:
		if not enemy.is_in_group("enemy"): continue
		
		# Line of site check
		line_of_site.target_position = line_of_site.to_local(enemy.global_position)
		line_of_site.force_raycast_update()
		if line_of_site.is_colliding(): continue # Blocked by wall
		
		# Scoring (Dot Product)
		var dir_to_enemy = (enemy.global_position - global_position).normalized()
		var camera_forward = -camera_controller.global_transform.basis.z
		var dot = camera_forward.dot(dir_to_enemy)
		var score = dot
		
		if score > highest_score:
			highest_score = score
			best_target = enemy

	line_of_site.target_position = Vector3.DOWN
	line_of_site.enabled = false

	return best_target
