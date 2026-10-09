extends Node3D
## Orbit camera on a SpringArm3D. Mouse look when captured, right stick on gamepad.

@export var mouse_sensitivity := 0.0025
@export var stick_sensitivity := 2.5
@export var min_pitch := -0.9
@export var max_pitch := 0.45
@export var default_distance := 7.0
@export var min_distance := 3.0
@export var max_distance := 14.0
@export var follow_lerp := 10.0

@onready var arm: SpringArm3D = $SpringArm3D

var _yaw := 0.0
var _pitch := -0.3

func _ready() -> void:
	arm.spring_length = default_distance
	top_level = true # don't inherit player rotation
	rotation = Vector3(_pitch, _yaw, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = clampf(arm.spring_length - 0.8, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = clampf(arm.spring_length + 0.8, min_distance, max_distance)
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("camera_toggle_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	var look := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if look.length() > 0.15:
		_yaw -= look.x * stick_sensitivity * delta
		_pitch = clampf(_pitch - look.y * stick_sensitivity * delta, min_pitch, max_pitch)
	rotation = Vector3(_pitch, _yaw, 0.0)
	var parent := get_parent() as Node3D
	if parent:
		var target := parent.global_position + Vector3(0, 1.4, 0)
		global_position = global_position.lerp(target, clampf(follow_lerp * delta, 0.0, 1.0))
