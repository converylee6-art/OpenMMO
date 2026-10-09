extends Node
## Autoload: loads data/region/oriana.json and exposes lookups.

const REGION_PATH := "res://data/region/oriana.json"

var region: Dictionary = {}
var locations_by_key: Dictionary = {}

func _ready() -> void:
	region = load_json(REGION_PATH)
	for loc in region.get("locations", []):
		locations_by_key[loc["key"]] = loc
	print("[RegionData] Loaded region '%s' with %d locations, %d routes" % [
		region.get("name", "?"), locations_by_key.size(), region.get("routes", []).size()])

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("JSON not found: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON at %s did not parse to a dictionary" % path)
		return {}
	return parsed

func get_location(key: String) -> Dictionary:
	return locations_by_key.get(key, {})

func routes_from(key: String) -> Array:
	var out: Array = []
	for r in region.get("routes", []):
		if r["from"] == key or r["to"] == key:
			out.append(r)
	return out
