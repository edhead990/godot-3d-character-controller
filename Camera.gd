extends Node3D

@export var reset_speed: float = 10.0 # Adjust for "snappiness"
@export var reset_threshold: float = 0.01
@export var joystick_sensitivity: Vector2 = Vector2(2.5, 2.0)
@export var mouse_sensitivity: Vector2 = Vector2(0.25, 0.125)
@export var mouse_enabled: bool = true

@onready var player: CharacterBody3D = get_parent().get_node("CharacterBody3D")
@onready var view: Area3D = get_node("SpringArm3D/View")
@onready var springarm: SpringArm3D = get_node("SpringArm3D")
@onready var ui: Control = get_parent().get_node("UserInterface")

var initial_position: Vector3
var initial_rotation: Vector3
var aiming_offset: Vector3 = Vector3(0.5, 0, 0)
var is_resetting: bool = false
var reset_to: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_position = global_position
	initial_rotation = global_rotation
	if mouse_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	if event is InputEventMouseMotion and mouse_enabled:
		rotation.y += deg_to_rad(-event.relative.x * mouse_sensitivity.x)
		rotation.x += deg_to_rad(-event.relative.y * mouse_sensitivity.y)
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(30))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x = player.global_position.x + initial_position.x
	global_position.y = player.global_position.y + initial_position.y
	global_position.z = player.global_position.z + initial_position.z
	
	if Input.is_action_just_pressed("aim"):
		enter_aim_mode()
	
	if Input.is_action_just_released("aim"):
		exit_aim_mode()

	var current_target = player.current_target
	
	if current_target and is_instance_valid(current_target) and Input.is_action_pressed("strafe"):
		# Calculate angle from camera to enemy
		var dir_to_enemy = (current_target.global_position - player.global_position).normalized()
		var target_yaw = atan2(-dir_to_enemy.x, -dir_to_enemy.z)
		var target_pitch = -0.3
		
		# Rotate from pivot point
		rotation.y = lerp_angle(rotation.y, target_yaw, 5.0 * delta)
		rotation.x = lerp_angle(rotation.x, target_pitch, 5.0 * delta)
	else:
		if Input.is_action_just_pressed("camera_reset"):
			start_camera_reset(player.rotation.y)

		if is_resetting:
			_perform_reset_step(delta)
		else:
			# Handle input
			var input_dir = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
			var direction = Vector3(input_dir.x, 0, input_dir.y)
			if direction:
				rotation.y += -direction.x * (joystick_sensitivity.x * delta)
				rotation.x += -direction.z * (joystick_sensitivity.y * delta)
				rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(30))


func start_camera_reset(target_y_rotation):
	reset_to = Vector2(initial_rotation.x, target_y_rotation)
	is_resetting = true


func _perform_reset_step(delta):
	var x_is_reset = abs(angle_difference(rotation.x, reset_to.x)) <= reset_threshold
	var y_is_reset = abs(angle_difference(rotation.y, reset_to.y)) <= reset_threshold

	if x_is_reset and y_is_reset:
		is_resetting = false
	else:
		rotation.x = lerp_angle(rotation.x, reset_to.x, reset_speed * delta)
		rotation.y = lerp_angle(rotation.y, reset_to.y, reset_speed * delta)


func enter_aim_mode():
	ui.get_node("Reticle").visible = true
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(springarm, "position", aiming_offset, 0.2)
	tween.tween_property(springarm, "spring_length", 1.0, 0.2)


func exit_aim_mode():
	ui.get_node("Reticle").visible = false
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(springarm, "position", Vector3.ZERO, 0.2)
	tween.tween_property(springarm, "spring_length", 2.8, 0.2)