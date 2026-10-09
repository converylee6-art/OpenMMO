extends Node
## Smoke test scene: run with `godot --headless res://tools/smoke_test.tscn`.
## Instantiates Pine Town and checks the grey-box built something.

func _ready() -> void:
	var scene := load("res://scenes/world/pine_town.tscn") as PackedScene
	assert(scene != null, "main scene failed to load")
	var inst := scene.instantiate()
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var town := inst.get_node("Town")
	var generated := get_tree().get_nodes_in_group("greybox_generated").size()
	var trees := town.get_node_or_null("Trees")
	var tree_count := trees.get_child_count() if trees else -1
	print("generated nodes: ", generated, " trees: ", tree_count)
	var ok := generated > 50 and tree_count > 80 and get_tree().get_first_node_in_group("player") != null
	print("SMOKE OK" if ok else "SMOKE FAIL")
	get_tree().quit(0 if ok else 1)
