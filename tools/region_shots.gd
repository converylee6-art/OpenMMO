extends Node
## Region screenshots. Run: godot --rendering-driver opengl3 --path . res://tools/region_shots.tscn

func _ready() -> void:
	var scene := load("res://scenes/region/oriana_region.tscn") as PackedScene
	var inst := scene.instantiate()
	var terrain: RegionTerrain = inst.get_node("Terrain")
	terrain.step = int(OS.get_environment("STEP")) if OS.get_environment("STEP") != "" else 2
	terrain.build_collision = false
	terrain.tree_count = 16000
	add_child(inst)
	if OS.get_environment("NO_OCEAN") == "1":
		terrain.get_node("Ocean").visible = false
	if OS.get_environment("PLAIN_MAT") == "1":
		var m := StandardMaterial3D.new(); m.albedo_color = Color(0.4, 0.6, 0.3)
		for c in terrain.get_children():
			if c is MeshInstance3D and c.name.begins_with("Chunk"):
				c.material_override = m
	var only: String = OS.get_environment("ONLY")
	var cam: Camera3D = inst.get_node("FlyCamera")
	cam.set_process(false); cam.set_process_unhandled_input(false)
	var out_dir: String = OS.get_environment("OUT_DIR")
	if out_dir.is_empty(): out_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var W := terrain.world_size()
	var shots := [
		{"name": "r01_whole_region", "pos": Vector3(W.x * 0.5, 2600, W.y * 1.55), "look": Vector3(W.x * 0.5, 0, W.y * 0.45)},
		{"name": "r02_pine_town_ground", "pos": terrain.map_to_world(Vector2(0.08, 0.26)) + Vector3(0, 6, 0), "look": terrain.map_to_world(Vector2(0.10, 0.18)) + Vector3(0, 8, 0)},
		{"name": "r03_mist_peak", "pos": terrain.map_to_world(Vector2(0.50, 0.50)) + Vector3(0, 250, 0), "look": terrain.map_to_world(Vector2(0.50, 0.15)) + Vector3(0, 150, 0)},
		{"name": "r04_emberfall_volcano", "pos": terrain.map_to_world(Vector2(0.72, 0.60)) + Vector3(0, 180, 0), "look": terrain.map_to_world(Vector2(0.905, 0.47)) + Vector3(0, 120, 0)},
		{"name": "r05_west_forest_air", "pos": terrain.map_to_world(Vector2(0.20, 0.95)) + Vector3(0, 500, 0), "look": terrain.map_to_world(Vector2(0.18, 0.45))},
		{"name": "r06_sapphire_coast", "pos": terrain.map_to_world(Vector2(0.62, 0.80)) + Vector3(0, 90, 0), "look": terrain.map_to_world(Vector2(0.74, 0.62)) + Vector3(0, 20, 0)},
	]
	for i in range(4): await get_tree().process_frame
	for s in shots:
		if not only.is_empty() and not s["name"].begins_with(only):
			continue
		cam.global_position = s["pos"]
		cam.look_at(s["look"], Vector3.UP)
		for i in range(8): await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join(s["name"] + ".png"))
		print("saved ", s["name"])
	get_tree().quit(0)
