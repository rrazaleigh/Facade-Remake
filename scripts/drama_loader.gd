# drama_loader.gd
# Autoload singleton — register as "DramaLoader" in Project Settings > Autoload
extends Node

var personas       : Dictionary = {}
var beats          : Dictionary = {}
var beat_order     : Array      = []
var tone_classifier : String    = ""

func _ready():
	_load_beats()
	_load_personas()
	_load_tone_classifier()

# ── BEATS ──────────────────────────────────────────────────────────────────────

func _load_beats():
	var raw = FileAccess.get_file_as_string("res://drama/beats.md")
	if raw == "":
		push_error("DramaLoader: beats.md not found")
		return

	var sections = raw.split("\n## ")
	for section in sections:
		section = section.strip_edges()
		if section == "" or section.begins_with("#"):
			continue

		var lines      = section.split("\n", false)
		var beat_name  = lines[0].strip_edges().to_lower()
		var directive  = ""
		var characters = []
		var in_directive = false

		for i in range(1, lines.size()):
			var line = lines[i].strip_edges()
			if line == "":
				continue
			if line.begins_with("CHARACTERS:"):
				var raw_chars = line.replace("CHARACTERS:", "").strip_edges()
				for ch in raw_chars.split(","):
					characters.append(ch.strip_edges())
				in_directive = false
			elif line.begins_with("PURPOSE:") or line.begins_with("DIALOGUE RULES:"):
				in_directive = true
				var content = line.substr(line.find(":") + 1).strip_edges()
				if content != "":
					directive += content + " "
			elif line.begins_with("EMOTIONAL STATE:") or line.begins_with("TRANSITIONS:"):
				in_directive = false
			elif in_directive:
				directive += line + " "

		beats[beat_name] = {
			"directive":  directive.strip_edges(),
			"characters": characters
		}
		beat_order.append(beat_name)

func get_directive(beat: String) -> String:
	return beats.get(beat, {}).get("directive", "")

func get_characters(beat: String) -> Array:
	return beats.get(beat, {}).get("characters", [])

# ── PERSONAS ───────────────────────────────────────────────────────────────────

func _load_personas():
	var dir = DirAccess.open("res://drama/personas/")
	if dir == null:
		push_error("DramaLoader: personas/ folder not found")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".md"):
			var key = file_name.replace(".md", "").to_lower()
			personas[key] = FileAccess.get_file_as_string(
				"res://drama/personas/" + file_name
			)
		file_name = dir.get_next()

func get_persona(character: String) -> String:
	return personas.get(character.to_lower(), "")

# ── TONE CLASSIFIER ────────────────────────────────────────────────────────────

func _load_tone_classifier():
	var raw = FileAccess.get_file_as_string("res://drama/tone_classifier.md")
	if raw == "":
		push_error("DramaLoader: tone_classifier.md not found")
		return
	tone_classifier = raw

func get_tone_classifier() -> String:
	return tone_classifier
