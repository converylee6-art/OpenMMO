class_name DoorTrigger
extends Area3D
## Placeholder for building entrances and route exits. Fires a message for now.

@export var target := ""
@export var kind := "door" # door | route

func _ready() -> void:
	collision_layer = 1 << 5
	collision_mask = 1 << 1
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if kind == "route":
			GameState.notify("Route exit: %s (not built yet)" % target)
		else:
			GameState.notify("Door: %s (interior not built yet)" % target)
