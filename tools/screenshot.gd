extends Node
## Captures screenshots of Pine Town from several camera positions.
## Run: godot --rendering-driver opengl3 --path . res://tools/screenshot.tscn
## Output: user://shots/*.png  (override dir with OUT_DIR env var)

var shots := [
	{"name": "01_spawn_view",    "pos": Vector3(-6, 3, 20),   "look": Vector3(0, 1, -6)},
	{"name": "02_overview",      "pos": Vector3(0, 45, 60),   "look": Vector3(4, 0, 0)},
	{"name": "03_lab",           "pos": Vector3(0, 4, 36),    "look": Vector3(14, 2, 20)},
	{"name": "04_player_house",  "pos": Vector3(-6, 3, -2),   "look": Vector3(-14, 2, -14)},
	{"name": "05_route_exit",    "pos": Vector3(24, 3, -2),   "look": Vector3(40, 1, -6)},
	{"name": "06_topdown",       "pos": Vector3(4, 90, 0.1),  "look": Vector3(4, 0, 0)},
]

func _ready() -> void:
	var scene := load("res://scenes/world/pine_town.tscn") as PackedScene
	var inst := scene.instantiate()
	add_child(inst)
	# disable the player's camera so ours wins
	var cam := Camera3D.new()
	cam.fov = 60
	add_child(cam)
	cam.make_current()
	var out_dir: String = OS.get_environment("OUT_DIR")
	if out_dir.is_empty():
		out_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	for i in range(3):
		await get_tree().process_frame
	for s in shots:
		cam.global_position = s["pos"]
		cam.look_at(s["look"], Vector3.UP)
		for i in range(6):
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var path := out_dir.path_join(s["name"] + ".png")
		img.save_png(path)
		print("saved ", path)
	get_tree().quit(0)
