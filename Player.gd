extends CharacterBody3D

@export var camera_controller = Node3D

@onready var view: Area3D = get_parent().get_node("CameraController/SpringArm3D/View")
@onready var line_of_site: RayCast3D = get_parent().get_node("CameraController/SpringArm3D/View/LineOfSite")

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var is_aiming = false
var is_strafing = false
var strafe_rotation: float = 0.0
var current_target: Node3D = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	# TODO: Consider adding buffer?
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle aim state
	if Input.is_action_pressed("aim"):
		is_aiming = true
	else:
		is_aiming = false
		
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
		
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if current_target and is_instance_valid(current_target):
		# Lock on
		var look_pos = current_target.global_position
		look_pos.y = global_position.y
		# Smooth rotation toward the target
		var target_basis = transform.looking_at(look_pos).basis
		transform.basis = transform.basis.slerp(target_basis, 12.0 * delta)
		
	elif is_strafing:
		rotation.y = strafe_rotation
		
	elif direction:
		# Smooth rotation in the movement direction
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), 12.0 * delta)
		
	move_and_slide()


func get_best_target() -> Node3D:
	var enemies = view.get_overlapping_bodies()
	var best_target = null
	var highest_score = -1.0 # Dot product range -1 to 1
	
	for enemy in enemies:
		if not enemy.is_in_group("enemy"): continue
		
		# Line of site check
		line_of_site.look_at(enemy.global_position)
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
	return best_target