class_name RegionTerrain
extends Node3D
## Builds the whole Oriana continent from assets/ours/terrain/*.png at runtime:
## chunked terrain mesh + collision, ocean, biome-scattered trees, location labels.

@export var step := 2                     # heightmap pixels per vertex (1 = full detail)
@export var chunks := Vector2i(8, 4)
@export var tree_count := 24000
@export var build_collision := true
@export var show_labels := true

const DIR := "res://assets/ours/terrain/"

var meta: Dictionary = {}
var width_px := 0
var height_px := 0
var mpp := 4.0
var max_h := 420.0
var sea_level := 25.0
var heights := PackedFloat32Array()    # metres, row-major
var biome_img: Image
var terrain_mat: ShaderMaterial

func _ready() -> void:
	meta = RegionData.load_json(DIR + "terrain.json")
	width_px = int(meta["width_px"]); height_px = int(meta["height_px"])
	mpp = float(meta["meters_per_px"]); max_h = float(meta["max_height_m"]); sea_level = float(meta["sea_level_m"])
	_load_heights()
	biome_img = _load_image("biomemap.png")
	_make_material()
	_build_chunks()
	_build_ocean()
	_scatter_trees()
	if show_labels:
		_place_labels()
	print("[RegionTerrain] %dx%d px, %.0fx%.0f m, step %d" % [width_px, height_px, world_size().x, world_size().y, step])

func world_size() -> Vector2:
	return Vector2(width_px * mpp, height_px * mpp)

func _load_image(name: String) -> Image:
	var img := Image.new()
	var err := img.load_png_from_buffer(FileAccess.get_file_as_bytes(DIR + name))
	if err != OK:
		push_error("RegionTerrain: cannot load " + name)
	return img

func _load_heights() -> void:
	var img := _load_image("heightmap_rg.png")
	img.convert(Image.FORMAT_RGB8)
	heights.resize(width_px * height_px)
	for y in range(height_px):
		for x in range(width_px):
			var c := img.get_pixel(x, y)
			var v := (roundf(c.r * 255.0) * 256.0 + roundf(c.g * 255.0)) / 65535.0
			heights[y * width_px + x] = v * max_h

func height_at_px(x: int, y: int) -> float:
	x = clampi(x, 0, width_px - 1); y = clampi(y, 0, height_px - 1)
	return heights[y * width_px + x]

## World position (x,z) -> terrain height, bilinear.
func height_at(wx: float, wz: float) -> float:
	var fx := wx / mpp; var fz := wz / mpp
	var x0 := int(floor(fx)); var z0 := int(floor(fz))
	var tx := fx - x0; var tz := fz - z0
	var h00 := height_at_px(x0, z0); var h10 := height_at_px(x0 + 1, z0)
	var h01 := height_at_px(x0, z0 + 1); var h11 := height_at_px(x0 + 1, z0 + 1)
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)

func biome_at(wx: float, wz: float) -> int:
	var x := clampi(int(wx / mpp), 0, width_px - 1); var y := clampi(int(wz / mpp), 0, height_px - 1)
	return int(roundf(biome_img.get_pixel(x, y).r * 255.0))

func map_to_world(norm: Vector2) -> Vector3:
	var wx := norm.x * world_size().x; var wz := norm.y * world_size().y
	return Vector3(wx, height_at(wx, wz), wz)

func _normal_at_px(x: int, y: int) -> Vector3:
	var l := height_at_px(x - 1, y); var r := height_at_px(x + 1, y)
	var d := height_at_px(x, y - 1); var u := height_at_px(x, y + 1)
	return Vector3(l - r, 2.0 * mpp, d - u).normalized()

func _make_material() -> void:
	terrain_mat = ShaderMaterial.new()
	terrain_mat.shader = load("res://shaders/terrain.gdshader")
	terrain_mat.set_shader_parameter("colormap", load(DIR + "colormap.png"))
	terrain_mat.set_shader_parameter("world_size", world_size())
	terrain_mat.set_shader_parameter("sea_level", sea_level)

func _build_chunks() -> void:
	var cw := width_px / chunks.x; var ch := height_px / chunks.y
	for cy in range(chunks.y):
		for cx in range(chunks.x):
			var x0 := cx * cw; var y0 := cy * ch
			var x1 := mini(x0 + cw, width_px - 1); var y1 := mini(y0 + ch, height_px - 1)
			_build_chunk(x0, y0, x1, y1)

func _build_chunk(x0: int, y0: int, x1: int, y1: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs := range(x0, x1 + 1, step); var ys := range(y0, y1 + 1, step)
	if xs[-1] != x1: xs.append(x1)
	if ys[-1] != y1: ys.append(y1)
	var nx := xs.size(); var nz := ys.size()
	for iz in range(nz):
		for ix in range(nx):
			var px: int = xs[ix]; var py: int = ys[iz]
			st.set_normal(_normal_at_px(px, py))
			st.set_uv(Vector2(float(px) / width_px, float(py) / height_px))
			st.add_vertex(Vector3(px * mpp, height_at_px(px, py), py * mpp))
	for iz in range(nz - 1):
		for ix in range(nx - 1):
			var a := iz * nx + ix; var b := a + 1; var c := a + nx; var d := c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = terrain_mat
	mi.name = "Chunk_%d_%d" % [x0, y0]
	add_child(mi)
	if build_collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = mesh.create_trimesh_shape()
		body.add_child(shape)
		mi.add_child(body)

func _build_ocean() -> void:
	var sz := world_size()
	var plane := PlaneMesh.new()
	plane.size = sz * 1.6
	plane.subdivide_width = 64; plane.subdivide_depth = 64
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(sz.x * 0.5, sea_level, sz.y * 0.5)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ocean.gdshader")
	mi.material_override = mat
	mi.name = "Ocean"
	add_child(mi)
	# invisible floor under the ocean so nothing falls forever
	var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(sz.x * 1.6, 1, sz.y * 1.6); cs.shape = bs; body.add_child(cs)
	body.position = Vector3(sz.x * 0.5, sea_level - 1.0, sz.y * 0.5)
	add_child(body)

func _tree_mesh(kind: int) -> ArrayMesh:
	# kind 0: pine (cones), 1: broadleaf (sphere blob), 2: palm-ish tall thin, 3: dead/volcanic
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new(); trunk.top_radius = 0.35; trunk.bottom_radius = 0.5; trunk.height = 3.0
	st.append_from(trunk, 0, Transform3D(Basis(), Vector3(0, 1.5, 0)))
	st.set_color(Color(0.35, 0.24, 0.14))
	var mesh := st.commit()
	var st2 := SurfaceTool.new(); st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		0:
			for i in range(3):
				var c := CylinderMesh.new(); c.top_radius = 0.0; c.bottom_radius = 3.0 - i * 0.8; c.height = 3.2; c.radial_segments = 7
				st2.append_from(c, 0, Transform3D(Basis(), Vector3(0, 3.4 + i * 1.7, 0)))
		1:
			var s := SphereMesh.new(); s.radius = 3.0; s.height = 5.0; s.radial_segments = 8; s.rings = 5
			st2.append_from(s, 0, Transform3D(Basis(), Vector3(0, 5.0, 0)))
		2:
			var s := SphereMesh.new(); s.radius = 2.2; s.height = 2.0; s.radial_segments = 7; s.rings = 3
			st2.append_from(s, 0, Transform3D(Basis(), Vector3(0, 7.0, 0)))
		_:
			var c := CylinderMesh.new(); c.top_radius = 0.1; c.bottom_radius = 0.3; c.height = 4.0; c.radial_segments = 5
			st2.append_from(c, 0, Transform3D(Basis(), Vector3(0, 4.5, 0)))
	var canopy := st2.commit()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, canopy.surface_get_arrays(0))
	var trunk_mat := StandardMaterial3D.new(); trunk_mat.albedo_color = Color(0.33, 0.22, 0.13)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = [Color(0.12, 0.36, 0.16), Color(0.25, 0.52, 0.2), Color(0.3, 0.6, 0.3), Color(0.25, 0.2, 0.18)][kind]
	mesh.surface_set_material(0, trunk_mat); mesh.surface_set_material(1, leaf_mat)
	return mesh

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 42
	var sz := world_size()
	# biome -> (tree kind, density weight)
	var rules := {3: [0, 1.0], 2: [1, 0.12], 1: [2, 0.05], 7: [3, 0.15], 4: [0, 0.08]}
	var buckets := {0: [], 1: [], 2: [], 3: []}
	var tries := 0
	var placed := 0
	while placed < tree_count and tries < tree_count * 6:
		tries += 1
		var wx := rng.randf() * sz.x; var wz := rng.randf() * sz.y
		var b := biome_at(wx, wz)
		if not rules.has(b):
			continue
		if rng.randf() > rules[b][1]:
			continue
		var h := height_at(wx, wz)
		if h < sea_level + 0.5:
			continue
		var n := _normal_at_px(int(wx / mpp), int(wz / mpp))
		if n.y < 0.75:
			continue
		var kind: int = rules[b][0]
		if b == 2 and h > 180.0:
			kind = 0
		var s := rng.randf_range(0.8, 1.4) * (1.2 if kind == 0 else 1.0)
		var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
		buckets[kind].append(Transform3D(basis, Vector3(wx, h - 0.3, wz)))
		placed += 1
	for kind in buckets:
		var list: Array = buckets[kind]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _tree_mesh(kind)
		mm.instance_count = list.size()
		for i in range(list.size()):
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "Trees_%d" % kind
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mmi)
	print("[RegionTerrain] trees placed: ", placed)

func _place_labels() -> void:
	for loc in RegionData.region.get("locations", []):
		var p := map_to_world(Vector2(loc["pos"][0], loc["pos"][1]))
		var l := Label3D.new()
		l.text = loc["name"]
		if loc.has("gym"):
			l.text += "\nGym %d" % loc["gym"]["number"]
		l.font_size = 160
		l.pixel_size = 0.05
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.outline_size = 24
		l.position = p + Vector3(0, 40, 0)
		l.no_depth_test = true
		add_child(l)
		var pin := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 1.5; cm.bottom_radius = 1.5; cm.height = 30
		pin.mesh = cm; pin.position = p + Vector3(0, 15, 0)
		var m := StandardMaterial3D.new(); m.albedo_color = Color(1, 0.3, 0.2); m.emission_enabled = true; m.emission = Color(1, 0.3, 0.2)
		pin.material_override = m
		add_child(pin)
