extends CanvasLayer
## Minimal HUD: location name, message toast, debug overlay (F3).

@onready var location_label: Label = %LocationLabel
@onready var toast: PanelContainer = %Toast
@onready var toast_label: Label = %ToastLabel
@onready var debug_label: Label = %DebugLabel
@onready var hint_label: Label = %HintLabel

var _toast_timer := 0.0

func _ready() -> void:
	GameState.message.connect(_show_toast)
	var loc := RegionData.get_location(GameState.current_location)
	location_label.text = loc.get("name", GameState.current_location.capitalize())
	toast.visible = false
	debug_label.visible = false
	hint_label.text = "WASD move · Shift run · E interact · Mouse look · Wheel zoom · Esc free mouse · F3 debug"

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast.visible = false
	if Input.is_action_just_pressed("debug_toggle"):
		debug_label.visible = not debug_label.visible
	if debug_label.visible:
		var p := get_tree().get_first_node_in_group("player") as Node3D
		var pos := p.global_position if p else Vector3.ZERO
		debug_label.text = "FPS %d\npos %.1f %.1f %.1f" % [Engine.get_frames_per_second(), pos.x, pos.y, pos.z]

func _show_toast(text: String) -> void:
	toast_label.text = text
	toast.visible = true
	_toast_timer = 3.5
