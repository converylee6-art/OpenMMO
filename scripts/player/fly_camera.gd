extends Camera3D
## Free-fly camera for touring the region. WASD + QE, Shift fast, mouse look.

@export var speed := 60.0
@export var fast_mult := 5.0
@export var sensitivity := 0.0025
var _yaw := 0.0
var _pitch := -0.3

func _ready() -> void:
	_yaw = rotation.y; _pitch = rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= e.relative.x * sensitivity
		_pitch = clampf(_pitch - e.relative.y * sensitivity, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0)
	elif e.is_action_pressed("camera_toggle_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif e is InputEventMouseButton and e.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	dir += -transform.basis.z * Input.get_axis("move_back", "move_forward")
	dir += transform.basis.x * Input.get_axis("move_left", "move_right")
	if Input.is_key_pressed(KEY_E): dir.y += 1
	if Input.is_key_pressed(KEY_Q): dir.y -= 1
	var s := speed * (fast_mult if Input.is_action_pressed("run") else 1.0)
	position += dir.normalized() * s * delta if dir.length() > 0 else Vector3.ZERO
