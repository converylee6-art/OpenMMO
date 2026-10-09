class_name Player
extends CharacterBody3D
## Third-person player controller. Movement is camera-relative.

@export var walk_speed := 4.0
@export var run_speed := 8.0
@export var acceleration := 14.0
@export var turn_speed := 12.0
@export var jump_velocity := 7.0

@onready var camera_rig: Node3D = $CameraRig
@onready var visual: Node3D = $Visual
@onready var interact_ray: RayCast3D = $Visual/InteractRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _facing := 0.0
var _focused_interactable: Node = null

func _ready() -> void:
	add_to_group("player")
	# Collide with world; be detectable by trigger areas via layer 2.
	collision_layer = 1 << 1
	collision_mask = 1

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis: Basis = camera_rig.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	var wish_dir := (right * input_dir.x + forward * input_dir.y)
	if wish_dir.length() > 1.0:
		wish_dir = wish_dir.normalized()

	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.lerp(wish_dir * target_speed, clampf(acceleration * delta, 0.0, 1.0))
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	if wish_dir.length() > 0.05:
		_facing = atan2(wish_dir.x, wish_dir.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, _facing, clampf(turn_speed * delta, 0.0, 1.0))

	move_and_slide()
	_update_interact_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _focused_interactable:
		_focused_interactable.interact(self)

func _update_interact_focus() -> void:
	var hit: Node = null
	if interact_ray.is_colliding():
		var c := interact_ray.get_collider()
		if c and c.has_method("interact"):
			hit = c
	if hit != _focused_interactable:
		if _focused_interactable and _focused_interactable.has_method("set_focused"):
			_focused_interactable.set_focused(false)
		_focused_interactable = hit
		if _focused_interactable and _focused_interactable.has_method("set_focused"):
			_focused_interactable.set_focused(true)

func get_speed_ratio() -> float:
	return Vector3(velocity.x, 0, velocity.z).length() / run_speed
