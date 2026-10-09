class_name Interactable
extends StaticBody3D
## Anything the player can press Interact on. Shows text through GameState.message.

@export_multiline var text := "..."
@export var title := ""

func _ready() -> void:
	collision_layer = 1 | (1 << 3)
	add_to_group("interactable")

func interact(_by: Node) -> void:
	var msg := text if title.is_empty() else "%s: %s" % [title, text]
	GameState.notify(msg)

func set_focused(on: bool) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.material_overlay:
			child.material_overlay.set("albedo_color", Color(1, 1, 0.6, 0.25) if on else Color(0, 0, 0, 0))
