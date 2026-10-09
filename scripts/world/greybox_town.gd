@tool
class_name GreyboxTown
extends Node3D
## Builds a grey-box town from data/world/<key>.json. Runs in editor (@tool) and at runtime.
## When a Meshy asset exists at assets/ours/meshy/<asset>.glb it is used instead of the box.

@export_file("*.json") var layout_path := "res://data/world/pine_town.json"
@export var rebuild := false:
	set(v):
		rebuild = false
		_build()

const MESHY_DIR := "res://assets/ours/meshy/"
const TREE_SCRIPT_GROUP := "greybox_generated"

var layout: Dictionary = {}
var _mat_cache: Dictionary = {}

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		if c.is_in_group(TREE_SCRIPT_GROUP):
			remove_child(c)
			c.queue_free()
	var text := FileAccess.get_file_as_string(layout_path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GreyboxTown: bad layout " + layout_path)
		return
	layout = parsed
	_build_ground()
	_build_paths()
	_build_water()
	_build_buildings()
	_build_props()
	_build_trees()
	_build_grass()
	_build_exits()

# ---------- helpers ----------

func _mat(color: Color, rough := 0.9) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), rough]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	_mat_cache[key] = m
	return m

func _add(node: Node, parent: Node = self) -> Node:
	parent.add_child(node)
	node.add_to_group(TREE_SCRIPT_GROUP)
	if Engine.is_editor_hint() and get_tree() and get_tree().edited_scene_root:
		node.owner = null # keep generated nodes out of the saved scene
	return node

func _box(size: Vector3, pos: Vector3, color: Color, rot_y := 0.0, collide := true, parent: Node = self) -> Node3D:
	var root: Node3D
	if collide:
		root = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		root.add_child(shape)
	else:
		root = Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	root.add_child(mi)
	root.position = pos
	root.rotation.y = deg_to_rad(rot_y)
	_add(root, parent)
	return root

func _label(text: String, pos: Vector3, size := 48, parent: Node = self) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.outline_size = 8
	l.position = pos
	_add(l, parent)
	return l

func _try_meshy(asset: String) -> Node3D:
	if asset.is_empty():
		return null
	var path := MESHY_DIR + asset + ".glb"
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			return scene.instantiate()
	return null

func _v2(a: Array) -> Vector2:
	return Vector2(a[0], a[1])

# ---------- builders ----------

func _build_ground() -> void:
	var sz: Array = layout.get("size", [80, 70])
	var c: Array = layout.get("ground_color", [0.36, 0.56, 0.28])
	var ground := _box(Vector3(sz[0] * 1.5, 1.0, sz[1] * 1.5), Vector3(0, -0.5, 0), Color(c[0], c[1], c[2]))
	ground.name = "Ground"
	# Outer boundary walls (invisible) so the player cannot walk off the grey-box.
	var hx: float = sz[0] * 0.75
	var hz: float = sz[1] * 0.75
	for wall in [[Vector3(hx, 0, 0), Vector3(1, 6, hz * 2)], [Vector3(-hx, 0, 0), Vector3(1, 6, hz * 2)],
			[Vector3(0, 0, hz), Vector3(hx * 2, 6, 1)], [Vector3(0, 0, -hz), Vector3(hx * 2, 6, 1)]]:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = wall[1]
		cs.shape = bs
		sb.add_child(cs)
		sb.position = wall[0] + Vector3(0, 3, 0)
		_add(sb)

func _build_paths() -> void:
	var col := Color(0.62, 0.52, 0.38)
	for p in layout.get("paths", []):
		var a := _v2(p["from"])
		var b := _v2(p["to"])
		var w: float = p.get("width", 3.0)
		var mid := (a + b) * 0.5
		var length := a.distance_to(b) + w
		var angle := atan2(b.x - a.x, b.y - a.y)
		var n := _box(Vector3(w, 0.06, length), Vector3(mid.x, 0.03, mid.y), col, rad_to_deg(angle), false)
		n.name = "Path"

func _build_water() -> void:
	for wtr in layout.get("water", []):
		var pos := _v2(wtr["pos"])
		var sz := _v2(wtr["size"])
		var n := _box(Vector3(sz.x, 0.1, sz.y), Vector3(pos.x, 0.02, pos.y), Color(0.2, 0.45, 0.8, 0.85), 0, true)
		n.name = "Water"
		(n.get_child(1) as MeshInstance3D).material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		(n.get_child(1) as MeshInstance3D).material_override.roughness = 0.1

func _build_buildings() -> void:
	for b in layout.get("buildings", []):
		var pos := _v2(b["pos"])
		var sz: Array = b["size"]
		var c: Array = b.get("color", [0.7, 0.7, 0.7])
		var rot: float = b.get("rot_deg", 0)
		var root := Node3D.new()
		root.name = "Building_" + b["id"]
		root.position = Vector3(pos.x, 0, pos.y)
		root.rotation.y = deg_to_rad(rot)
		_add(root)
		var meshy := _try_meshy(b.get("asset", ""))
		if meshy:
			root.add_child(meshy)
			# Keep a collision box even for real models until we bake proper collision.
			var sb := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new(); bs.size = Vector3(sz[0], sz[1], sz[2]); cs.shape = bs
			sb.add_child(cs); sb.position.y = sz[1] * 0.5
			root.add_child(sb)
		else:
			_box(Vector3(sz[0], sz[1], sz[2]), Vector3(0, sz[1] * 0.5, 0), Color(c[0], c[1], c[2]), 0, true, root)
			# simple roof wedge for readability
			var roof := _box(Vector3(sz[0] + 0.6, 0.4, sz[2] + 0.6), Vector3(0, sz[1] + 0.2, 0), Color(c[0] * 0.6, c[1] * 0.5, c[2] * 0.5), 0, false, root)
			roof.name = "Roof"
		_label(b.get("label", b["id"]), Vector3(0, sz[1] + 1.6, 0), 56, root)
		# door trigger on the requested side (local space, before rotation)
		var door := DoorTrigger.new()
		door.target = b["id"]
		var dcs := CollisionShape3D.new()
		var dbs := BoxShape3D.new(); dbs.size = Vector3(2.0, 2.5, 1.2); dcs.shape = dbs
		door.add_child(dcs)
		var side: String = b.get("door_side", "south")
		door.position = Vector3(0, 1.2, sz[2] * 0.5 + 0.7) if side == "south" else Vector3(0, 1.2, -(sz[2] * 0.5 + 0.7))
		root.add_child(door)
		door.add_to_group(TREE_SCRIPT_GROUP)
		var mat := _box(Vector3(2.0, 0.05, 1.4), door.position - Vector3(0, 1.2, 0), Color(0.45, 0.3, 0.2), 0, false, root)
		mat.name = "DoorMat"

func _build_props() -> void:
	for p in layout.get("props", []):
		match p["type"]:
			"sign":
				var pos := _v2(p["pos"])
				var s := Interactable.new()
				s.name = "Sign"
				s.title = "Sign"
				s.text = p.get("text", "")
				s.position = Vector3(pos.x, 0, pos.y)
				s.rotation.y = deg_to_rad(p.get("rot_deg", 0))
				var post := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.08; cm.bottom_radius = 0.1; cm.height = 1.2
				post.mesh = cm; post.position.y = 0.6; post.material_override = _mat(Color(0.4, 0.28, 0.16))
				var board := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.4, 0.6, 0.08)
				board.mesh = bm; board.position.y = 1.4; board.material_override = _mat(Color(0.55, 0.4, 0.25))
				var overlay := StandardMaterial3D.new(); overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				overlay.albedo_color = Color(0, 0, 0, 0); board.material_overlay = overlay
				var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(1.4, 1.8, 0.4); cs.shape = bs; cs.position.y = 0.9
				s.add_child(post); s.add_child(board); s.add_child(cs)
				_add(s)
			"lamp":
				var pos := _v2(p["pos"])
				var root := _box(Vector3(0.18, 3.2, 0.18), Vector3(pos.x, 1.6, pos.y), Color(0.2, 0.2, 0.22))
				root.name = "Lamp"
				var light := OmniLight3D.new(); light.position.y = 1.7; light.light_color = Color(1, 0.85, 0.6)
				light.light_energy = 2.0; light.omni_range = 9.0; light.shadow_enabled = false
				root.add_child(light)
				var bulb := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.44
				bulb.mesh = sm; bulb.position.y = 1.7
				var em := StandardMaterial3D.new(); em.emission_enabled = true; em.emission = Color(1, 0.8, 0.5); em.emission_energy_multiplier = 2.0
				bulb.material_override = em; root.add_child(bulb)
			"bench":
				var pos := _v2(p["pos"])
				_box(Vector3(1.8, 0.45, 0.6), Vector3(pos.x, 0.225, pos.y), Color(0.5, 0.35, 0.2), p.get("rot_deg", 0)).name = "Bench"
			"well":
				var pos := _v2(p["pos"])
				var w := StaticBody3D.new(); w.name = "Well"; w.position = Vector3(pos.x, 0, pos.y)
				var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 1.0; cm.bottom_radius = 1.1; cm.height = 1.0
				mi.mesh = cm; mi.position.y = 0.5; mi.material_override = _mat(Color(0.5, 0.5, 0.52))
				var cs := CollisionShape3D.new(); var cys := CylinderShape3D.new(); cys.radius = 1.1; cys.height = 1.0; cs.shape = cys; cs.position.y = 0.5
				w.add_child(mi); w.add_child(cs); _add(w)
			"mailbox":
				var pos := _v2(p["pos"])
				_box(Vector3(0.4, 1.2, 0.4), Vector3(pos.x, 0.6, pos.y), Color(0.8, 0.15, 0.15)).name = "Mailbox"
			"flower_bed":
				var pos := _v2(p["pos"]); var sz := _v2(p["size"])
				_box(Vector3(sz.x, 0.3, sz.y), Vector3(pos.x, 0.15, pos.y), Color(0.85, 0.35, 0.55)).name = "FlowerBed"
			"fence":
				var a := _v2(p["from"]); var b := _v2(p["to"])
				var mid := (a + b) * 0.5; var length := a.distance_to(b)
				var angle := rad_to_deg(atan2(b.x - a.x, b.y - a.y))
				_box(Vector3(0.15, 1.0, length), Vector3(mid.x, 0.5, mid.y), Color(0.6, 0.45, 0.3), angle).name = "Fence"

func _build_trees() -> void:
	var t: Dictionary = layout.get("trees", {})
	if t.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t.get("seed", 1))
	var placed: Array[Vector2] = []
	var keep_out: Array = t.get("keep_out", [])
	var bld_rects: Array = []
	for b in layout.get("buildings", []):
		var p := _v2(b["pos"]); var s: Array = b["size"]
		bld_rects.append(Rect2(p - Vector2(s[0], s[2]) * 0.5 - Vector2(2, 2), Vector2(s[0], s[2]) + Vector2(4, 4)))
	var spacing: float = t.get("ring", {}).get("min_spacing", 3.0)
	var trees_root := Node3D.new(); trees_root.name = "Trees"; _add(trees_root)
	var ring: Dictionary = t.get("ring", {})
	if not ring.is_empty():
		var inner: Array = ring["inner"]; var outer: Array = ring["outer"]
		var tries := 0
		while placed.size() < int(ring["count"]) and tries < 4000:
			tries += 1
			var p := Vector2(rng.randf_range(outer[0], outer[2]), rng.randf_range(outer[1], outer[3]))
			if p.x > inner[0] and p.x < inner[2] and p.y > inner[1] and p.y < inner[3]:
				continue
			if _blocked(p, placed, spacing, keep_out, bld_rects):
				continue
			placed.append(p)
			_tree(p, rng, trees_root)
	for cl in t.get("clusters", []):
		var c := _v2(cl["center"]); var r: float = cl["radius"]
		var n := 0; var tries := 0
		while n < int(cl["count"]) and tries < 400:
			tries += 1
			var p := c + Vector2(rng.randf_range(-r, r), rng.randf_range(-r, r))
			if _blocked(p, placed, spacing * 0.8, keep_out, bld_rects):
				continue
			placed.append(p); n += 1
			_tree(p, rng, trees_root)

func _blocked(p: Vector2, placed: Array[Vector2], spacing: float, keep_out: Array, rects: Array) -> bool:
	for q in placed:
		if p.distance_to(q) < spacing:
			return true
	for k in keep_out:
		var a := _v2(k["from"]); var b := _v2(k["to"])
		if p.x >= a.x and p.x <= b.x and p.y >= a.y and p.y <= b.y:
			return true
	for r in rects:
		if r.has_point(p):
			return true
	# keep paths clear
	for path in layout.get("paths", []):
		var a := _v2(path["from"]); var b := _v2(path["to"])
		var seg := Geometry2D.get_closest_point_to_segment(p, a, b)
		if seg.distance_to(p) < path.get("width", 3.0) * 0.5 + 1.5:
			return true
	return false

func _tree(p: Vector2, rng: RandomNumberGenerator, parent: Node) -> void:
	var scale := rng.randf_range(0.8, 1.35)
	var root := StaticBody3D.new()
	root.position = Vector3(p.x, 0, p.y)
	root.rotation.y = rng.randf_range(0, TAU)
	var meshy := _try_meshy("b1_pine_tree")
	if meshy:
		meshy.scale = Vector3.ONE * scale
		root.add_child(meshy)
	else:
		var trunk := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.25 * scale; cm.bottom_radius = 0.35 * scale; cm.height = 2.0 * scale
		trunk.mesh = cm; trunk.position.y = 1.0 * scale; trunk.material_override = _mat(Color(0.35, 0.24, 0.14))
		root.add_child(trunk)
		var y := 1.6 * scale
		for i in range(3):
			var cone := MeshInstance3D.new(); var cmesh := CylinderMesh.new()
			var r := (2.2 - i * 0.55) * scale
			cmesh.top_radius = 0.0; cmesh.bottom_radius = r; cmesh.height = 2.4 * scale; cmesh.radial_segments = 10
			cone.mesh = cmesh; cone.position.y = y + 1.2 * scale
			cone.material_override = _mat(Color(0.12, 0.38 + i * 0.05, 0.16))
			root.add_child(cone)
			y += 1.3 * scale
	var cs := CollisionShape3D.new(); var cys := CylinderShape3D.new(); cys.radius = 0.5 * scale; cys.height = 3.0; cs.shape = cys; cs.position.y = 1.5
	root.add_child(cs)
	_add(root, parent)

func _build_grass() -> void:
	for g in layout.get("grass_patches", []):
		var pos := _v2(g["pos"]); var sz := _v2(g["size"])
		var area := EncounterGrass.new()
		area.name = "TallGrass"
		area.route_id = str(g.get("route", ""))
		area.position = Vector3(pos.x, 0.5, pos.y)
		var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(sz.x, 1.0, sz.y); cs.shape = bs
		area.add_child(cs)
		# visual: a grid of thin dark-green boxes as grass tufts
		var rng := RandomNumberGenerator.new(); rng.seed = 99
		var mm := MultiMeshInstance3D.new(); var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		var tuft := BoxMesh.new(); tuft.size = Vector3(0.5, 0.9, 0.5)
		multi.mesh = tuft
		var cols := int(sz.x / 0.9); var rows := int(sz.y / 0.9)
		multi.instance_count = cols * rows
		var i := 0
		for x in range(cols):
			for z in range(rows):
				var lp := Vector3(-sz.x * 0.5 + 0.45 + x * 0.9 + rng.randf_range(-0.2, 0.2), -0.05, -sz.y * 0.5 + 0.45 + z * 0.9 + rng.randf_range(-0.2, 0.2))
				multi.set_instance_transform(i, Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU), lp))
				i += 1
		mm.multimesh = multi; mm.material_override = _mat(Color(0.15, 0.42, 0.18))
		area.add_child(mm)
		_add(area)

func _build_exits() -> void:
	for e in layout.get("exits", []):
		var pos := _v2(e["pos"]); var sz: Array = e["size"]
		var d := DoorTrigger.new(); d.kind = e.get("kind", "route"); d.target = e["target"]; d.name = "Exit_" + e["target"]
		d.position = Vector3(pos.x, sz[1] * 0.5, pos.y)
		var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(sz[0], sz[1], sz[2]); cs.shape = bs
		d.add_child(cs)
		_add(d)
		_label("→ " + e["target"].capitalize(), Vector3(pos.x, 3.0, pos.y), 48)
