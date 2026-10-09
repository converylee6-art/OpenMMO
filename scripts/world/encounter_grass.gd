class_name EncounterGrass
extends Area3D
## Tall grass zone. For the grey-box it only reports entry; M4 hooks the encounter table here.

@export var route_id := "101"
var _player_inside := false

func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	body_entered.connect(func(b): if b.is_in_group("player"): _player_inside = true; GameState.notify("Entered tall grass (route %s)" % route_id))
	body_exited.connect(func(b): if b.is_in_group("player"): _player_inside = false)
