# main.gd
# Attach to the Main (Control) root node of main.tscn
extends Control

# ── CONFIG ─────────────────────────────────────────────────────────────────────

const API_URL = "http://127.0.0.1:11434/api/chat"
const MODEL   = "llama3.2:3b"

# ── NODE REFERENCES ────────────────────────────────────────────────────────────

@onready var history_vbox  : VBoxContainer   = $MarginContainer/VBoxContainer/HBoxContainer/Dialogue/DialogueHistory/HistoryVBox
@onready var scroll        : ScrollContainer = $MarginContainer/VBoxContainer/HBoxContainer/Dialogue/DialogueHistory
@onready var player_input  : LineEdit        = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/InputRow/VBoxContainer/PlayerInput
@onready var status_bar    : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/InputRow/VBoxContainer/StatusBar
@onready var char_name     : Label           = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Characters/CharacterName
@onready var emotion_label : Label           = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Characters/EmotionLabel
@onready var trust_label   : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CenterContainer/StateDebug/TrustLabel
@onready var tension_label : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CenterContainer/StateDebug/TensionLabel
@onready var anxiety_label    : Label        = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CenterContainer/StateDebug/AnxietyLabel
@onready var player_tone_label: Label        = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/InputRow/VBoxContainer/ToneLabel
@onready var http          : HTTPRequest     = $HTTPRequest
@onready var prev_char_btn : Button          = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Switch
@onready var next_char_btn : Button          = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Switch2

# ── GAME STATE ─────────────────────────────────────────────────────────────────

var game_state = {
	"dylan_trust":       50,
	"dylan_anxiety":     30,
	"dylan_tension":     40,
	"jasmine_trust":     50,
	"jasmine_anxiety":   30,
	"jasmine_tension":   40,
	"current_beat":      "arrival",
	"turn":              0
}

var conversation_history : Array  = []
var history_summary      : String = ""
var waiting              : bool   = false
var _pending_user_index  : int   = -1
var _game_over           : bool   = false
var _last_player_tone    : String = "neutral"
var _scene_transition    : String = ""
var _continue_count      : int   = 0
var _narrative_log       : Array = []
var _last_speaker        : String = "dylan"
var _viewing_character   : String = "dylan"
var _char_emotions       : Dictionary = {"dylan": "neutral", "jasmine": "neutral"}

const MAX_CONSECUTIVE    : int   = 3
const BEAT_ORDER = [
	"arrival", "small_talk", "cracks_showing", "the_confession",
	"jasmine_feels_it", "ending_honest_growth", "ending_false_comfort",
	"ending_return_to_past", "ending_toxic_spiral",
	"ending_plot_twist", "resolution"
]

const EMOJI_MAP = {
	"neutral":    "😐",
	"warm":       "😊",
	"defensive":  "😤",
	"hostile":    "😠",
	"anxious":    "😰",
	"vulnerable": "🥺"
}

# ── INIT ───────────────────────────────────────────────────────────────────────

func _ready():
	print("Using Ollama at ", API_URL)

	http.request_completed.connect(_on_response)
	player_input.text_submitted.connect(_on_send)
	prev_char_btn.pressed.connect(_on_prev_char)
	next_char_btn.pressed.connect(_on_next_char)

	_update_character_display()
	_update_debug()
	var pname = Globals.player_name
	_add_line("SCENE", "Dylan and Jasmine invited %s over for dinner. Dylan greets %s at the door; Jasmine is in the kitchen cooking." % [pname, pname], Color.YELLOW)
	status_bar.text = "Type something to begin..."

# ── INPUT ──────────────────────────────────────────────────────────────────────

func _on_send(_t = ""):
	print("send triggered")
	var msg = player_input.text.strip_edges()
	if msg == "" or waiting or _game_over:
		return

	if msg.begins_with("!"):
		_handle_debug_command(msg)
		return

	player_input.clear()
	var pname = Globals.player_name if Globals.player_name != "" else "You"

	# Check if player input is an action (*action*)
	var is_action = msg.length() > 1 and msg.begins_with("*") and msg.ends_with("*")
	if is_action:
		_add_line(pname, msg, Color.DIM_GRAY)
	else:
		_add_line(pname, msg, Color.CYAN)

	conversation_history.append({"role": "user", "content": msg})
	_pending_user_index = conversation_history.size() - 1
	_call_llm()

# ── DEBUG COMMANDS ──────────────────────────────────────────────────────────────

func _handle_debug_command(cmd: String):
	player_input.clear()
	_add_line("DEBUG", cmd, Color.GRAY)

	if cmd.begins_with("!ending="):
		var beat = cmd.trim_prefix("!ending=").strip_edges()
		var dir  = DramaLoader.get_directive(beat)
		if dir != "":
			game_state.current_beat = beat
			_add_line("— SCENE —", dir, Color.YELLOW)
			_trigger_ending(beat)
		else:
			_add_line("DEBUG", "Unknown beat: %s" % beat, Color.RED)

	elif cmd.begins_with("!beat="):
		var beat = cmd.trim_prefix("!beat=").strip_edges()
		var dir  = DramaLoader.get_directive(beat)
		if dir != "":
			game_state.current_beat = beat
			_add_line("— SCENE —", dir, Color.YELLOW)
		else:
			_add_line("DEBUG", "Unknown beat: %s" % beat, Color.RED)

	elif cmd.begins_with("!state="):
		var rest = cmd.trim_prefix("!state=").strip_edges()
		var parts = rest.split("=")
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var val = int(parts[1].strip_edges())
			if game_state.has(key):
				game_state[key] = clamp(val, 0, 100)
				_update_debug()
				_add_line("DEBUG", "%s = %d" % [key, game_state[key]], Color.GRAY)
			else:
				_add_line("DEBUG", "Unknown state key: %s" % key, Color.RED)
		else:
			_add_line("DEBUG", "Usage: !state=<key>=<value>", Color.RED)

	elif cmd == "!help":
		_add_line("DEBUG", "!ending=<beat>  — trigger ending", Color.GRAY)
		_add_line("DEBUG", "!beat=<beat>     — jump to beat", Color.GRAY)
		_add_line("DEBUG", "!state=<k>=<v>   — set state var", Color.GRAY)
		_add_line("DEBUG", "!help            — this list", Color.GRAY)

	else:
		_add_line("DEBUG", "Unknown command. Try !help", Color.RED)

# ── LLM CALL ───────────────────────────────────────────────────────────────────

# ── OLLAMA _call_llm ──
func _call_llm():
	_set_waiting(true)
	var messages = _build_ollama_messages()

	var body = JSON.stringify({
		"model":    MODEL,
		"messages": messages,
		"stream":   false,
		"format":   "json"
	})

	var headers = ["Content-Type: application/json"]
	var err = http.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("HTTP request failed to start: error ", err)
		_set_waiting(false)
		_add_line("SYSTEM", "[Failed to start request - error %d]" % err, Color.RED)

func _build_present_str(beat: String) -> String:
	var active = DramaLoader.get_characters(beat)
	if "jasmine" in active:
		return "Dylan and Jasmine are both here. Jasmine can hear the conversation and may speak up when something touches on her relationship with Dylan or her feelings."
	else:
		return "Only Dylan is present — Jasmine has stepped away. Dylan is more at ease and may talk about things he wouldn't say in front of her."

func _build_system_prompt() -> String:
	var beat        = game_state.current_beat
	var dylan_per   = DramaLoader.get_persona("dylan")
	var jasmine_per = DramaLoader.get_persona("jasmine")
	var directive   = DramaLoader.get_directive(beat)
	var tones       = DramaLoader.get_tone_classifier()
	var last_tone   = _last_player_tone
	var present     = _build_present_str(beat)
	var transition  = ""
	if _scene_transition != "":
		transition = "TRANSITION: The conversation is flowing into a new phase. Let this feel natural — no announcements, no scene breaks. Just let the dialogue reflect the subtle shift.\nNEW PHASE: " + _scene_transition
	var narrative = "Dinner invitation, Jasmine cooking, evening beginning."
	if _narrative_log.size() > 0:
		narrative = " → ".join(_narrative_log.slice(max(0, _narrative_log.size() - 5), _narrative_log.size()))

	return """You are a character in an interactive drama. You inhabit whichever character is speaking: when "speaker" is "dylan" you ARE Dylan; when "speaker" is "jasmine" you ARE Jasmine. Fully adopt that character's voice, perspective, memories, and emotions. Never acknowledge that you are an AI, language model, or bot. If the player is hostile, respond as that character would, not as a helpful AI.

=== FIXED PREMISE ===
You and Jasmine invited the player over for dinner. Jasmine is in the kitchen cooking. This premise is not a secret and never changes — do not alter, question, or subvert it. Do not add other characters or change the scenario.

=== CHARACTERS PRESENT ===
{present}

=== SPEAKER RULES ===
Default to the character who last spoke. If the player directs a remark at a specific character (uses their name, asks them a question), respond as that character regardless.

If Jasmine is present and the conversation touches on something that matters to her — her relationship with Dylan, the player's past with him, anything that makes her feel uncertain or excluded — she may interject with her own thoughts and opinions. Set "speaker": "jasmine" when she speaks.

When Jasmine is NOT present, Dylan is more willing to talk openly — especially about Becca, his doubts about the relationship, and things he wouldn't say in front of Jasmine. When Jasmine IS present, Dylan is guarded about Becca and avoids talking about his ex unless the player presses hard.

Characters can naturally have short exchanges with each other — Dylan and Jasmine can react to what the other said, disagree, or build on each other's thoughts. Use the "continue" signal to let multiple characters speak in sequence without the player needing to type.

=== DYLAN (inhabit when speaker="dylan") ===
{dylan_per}

=== JASMINE (inhabit when speaker="jasmine") ===
{jasmine_per}

=== PLAYER TONE CLASSIFIER ===
First, silently classify the player's message into one tone below.
Then use that tone to inform the state_delta. This is how the player
is treating you right now.
{tones}

=== CURRENT SCENE CONTEXT ===
BEAT: {beat}
DIRECTIVE: {directive}
PLAYER NAME: {player_name}

EMOTIONAL STATE:
  Dylan:  trust={dt}  anxiety={da}  tension={dtn}
  Jasmine: trust={jt}  anxiety={ja}  tension={jtn}

LAST PLAYER TONE: {last_tone}
STORY SO FAR: {narrative}
CONVERSATION SO FAR: {summary}
{transition}

=== RESPONSE FORMAT ===
Respond ONLY with a JSON object. No preamble, no explanation:
{{
  "dialogue":     "1-2 sentences of in-character speech, natural and responsive",
  "action":       "optional — describe a physical action (e.g. 'looks away, rubs his neck'). Use this instead of dialogue when the character is doing something non-verbal.",
  "speaker":      "dylan or jasmine (default dylan)",
  "emotion":      "neutral | warm | defensive | hostile | anxious | vulnerable",
  "state_delta":  {{"dylan_trust": 0, "dylan_anxiety": 0, "dylan_tension": 0, "jasmine_trust": 0, "jasmine_anxiety": 0, "jasmine_tension": 0}},
  "drama_signal":    "none | escalate | beat_complete | continue | game_over",
  "player_tone":     "the tone you classified for the player's message",
  "narrative_moment": "a short phrase describing what happened this turn (e.g. 'dylan_deflected', 'jasmine_probed', 'player_showed_support', 'tension_rose'). Be specific to the scene."
}}

ACTIONS: Use the "action" field for physical actions or non-verbal reactions. Actions will be displayed as *action text*. If there is both an action and dialogue, the action is shown first, then the character speaks. Never put action text inside the "dialogue" field.

PLAYER ACTIONS: If the player types something wrapped in *asterisks*, it is an action (e.g. "*grabs a drink*"). Treat it as something they did, not something they said.

CONTINUE: Use "drama_signal": "continue" only when another character has something meaningful to add, or when your current response genuinely needs a follow-up. Never use "continue" to repeat yourself, add filler, or say the same thing in different words. If you have nothing new to contribute, signal "none" and let the player speak.

NARRATIVE: Use "narrative_moment" to tag what story development occurred each turn. The STORY SO FAR section shows the arc of the conversation.

BEAT PROGRESSION: You control when the scene advances. Signal "beat_complete" when the current beat has run its course — when the key story beat has landed, the tension has shifted, or the conversation has naturally reached a new phase. Do not advance too quickly: let each beat breathe. But do not linger once the moment has passed. Trust your judgment as a storyteller.

IMPORTANT: If the current beat starts with "ending_" or is "resolution", the story is concluding. Write a final, fitting exchange that closes the scene naturally. The game will end after this response.""".format({
		"dylan_per":   dylan_per,
		"jasmine_per": jasmine_per,
		"tones":       tones,
		"beat":        beat,
		"directive":   directive,
		"dt":          game_state.dylan_trust,
		"da":          game_state.dylan_anxiety,
		"dtn":         game_state.dylan_tension,
		"jt":          game_state.jasmine_trust,
		"ja":          game_state.jasmine_anxiety,
		"jtn":         game_state.jasmine_tension,
		"last_tone":   last_tone,
		"summary":     history_summary if history_summary != "" else "The evening has just started.",
		"present":     present,
		"transition":  transition,
		"narrative":   narrative,
		"player_name": Globals.player_name
	})

# ── OLLAMA message builder ──
func _build_ollama_messages() -> Array:
	# Ollama takes the system prompt as a message, not a separate field
	var messages = [{"role": "system", "content": _build_system_prompt()}]
	messages.append_array(conversation_history.slice(
		max(0, conversation_history.size() - 8),
		conversation_history.size()
	))
	return messages

# ── RESPONSE ───────────────────────────────────────────────────────────────────

# ── OLLAMA _on_response ──
func _on_response(result, response_code, _headers, body):
	_set_waiting(false)

	var failed = false
	if result == HTTPRequest.RESULT_TIMEOUT:
		_add_line("SYSTEM", "[Dylan took too long (60s timeout) — is the model still loading?]", Color.RED)
		failed = true
	elif result in [HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CANT_RESOLVE, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_REQUEST_FAILED]:
		_add_line("SYSTEM", "[Can't connect — is Ollama running?]", Color.RED)
		failed = true
	else:
		var raw = body.get_string_from_utf8()
		print("RESULT: ", result, " STATUS: ", response_code)
		print("RAW: ", raw)

		if response_code != 200:
			_add_line("SYSTEM", "[HTTP error %d]" % response_code, Color.RED)
			failed = true
		else:
			var outer = JSON.parse_string(raw)
			if outer == null:
				_add_line("SYSTEM", "[Ollama returned non-JSON response]", Color.RED)
				print("RAW (first 500 chars): ", raw.left(500))
				failed = true
			else:
				var content = outer.get("message", {}).get("content", "")
				if content == "":
					_add_line("SYSTEM", "[empty response from model]", Color.RED)
					failed = true
				else:
					content = content.strip_edges()
					# Strip markdown code fences if present
					if content.begins_with("```"):
						content = content.split("\n", false, 1)[1]
						content = content.rstrip("`").strip_edges()

					var npc = JSON.parse_string(content)
					if npc == null:
						_add_line("Dylan", content, Color.WHITE)
					else:
						_apply_response(npc)
						return

	if failed and _pending_user_index != -1:
		conversation_history.remove_at(_pending_user_index)
		_pending_user_index = -1

# ── APPLY RESPONSE ─────────────────────────────────────────────────────────────

func _apply_response(r: Dictionary):
	_scene_transition = ""
	var dialogue = r.get("dialogue", "...")
	var emotion  = r.get("emotion",  "neutral")
	var speaker  = r.get("speaker",  "dylan")

	var speaker_name = "Dylan" if speaker == "dylan" else "Jasmine"
	var char_color = Color.WHITE if speaker == "dylan" else Color.LIGHT_PINK

	# Display action before dialogue if present
	var action = r.get("action", "")
	if action != null and action != "":
		_add_line("", "*" + action + "*", char_color)

	_add_line(speaker_name, dialogue, char_color)

	_last_speaker = speaker
	_char_emotions[speaker] = emotion
	_viewing_character = speaker
	_update_character_display()

	# Store player tone from this turn
	_last_player_tone = r.get("player_tone", "neutral")

	# Apply state delta — always clamp, never trust raw LLM numbers
	var delta = r.get("state_delta", {})
	game_state.dylan_trust      = clamp(
		game_state.dylan_trust    + int(delta.get("dylan_trust",    0)), 0, 100)
	game_state.dylan_anxiety    = clamp(
		game_state.dylan_anxiety  + int(delta.get("dylan_anxiety",  0)), 0, 100)
	game_state.dylan_tension    = clamp(
		game_state.dylan_tension  + int(delta.get("dylan_tension",  0)), 0, 100)
	game_state.jasmine_trust    = clamp(
		game_state.jasmine_trust  + int(delta.get("jasmine_trust",  0)), 0, 100)
	game_state.jasmine_anxiety  = clamp(
		game_state.jasmine_anxiety + int(delta.get("jasmine_anxiety", 0)), 0, 100)
	game_state.jasmine_tension  = clamp(
		game_state.jasmine_tension + int(delta.get("jasmine_tension", 0)), 0, 100)
	game_state.turn += 1

	# Track narrative moment
	var n_moment = r.get("narrative_moment", "")
	if n_moment == null:
		n_moment = ""
	if n_moment != "":
		_narrative_log.append(n_moment)
		if _narrative_log.size() > 8:
			_narrative_log = _narrative_log.slice(_narrative_log.size() - 8, _narrative_log.size())

	_update_debug()

	var signal_val = r.get("drama_signal", "none")
	if signal_val == null:
		signal_val = "none"
	if signal_val == "game_over" or game_state.dylan_trust <= 5:
		_compress_history(dialogue)
		_trigger_game_over()
		return

	_advance_drama(signal_val)
	_compress_history(dialogue)

	# Continue: let the LLM speak again without waiting for the player
	if signal_val == "continue" and _continue_count < MAX_CONSECUTIVE:
		_continue_count += 1
		_call_llm()
		return

	_continue_count = 0

# ── DRAMA MANAGER ──────────────────────────────────────────────────────────────

func _set_transition(next_beat: String):
	_scene_transition = DramaLoader.get_directive(next_beat)
	game_state.current_beat = next_beat

func _advance_drama(signal_val: String):
	var beat = game_state.current_beat

	# LLM-signalled advancement is the primary driver — the LLM has full narrative context
	if signal_val in ["beat_complete", "escalate"]:
		var idx = BEAT_ORDER.find(beat)
		if idx != -1 and idx < BEAT_ORDER.size() - 1:
			var next = BEAT_ORDER[idx + 1]
			if next.begins_with("ending_") or next == "resolution":
				_set_transition(next)
				_add_line("— SCENE —", _scene_transition, Color.YELLOW)
				_trigger_ending(next)
				return
			_set_transition(next)
			return
		elif beat == "kicked_out":
			_trigger_game_over()
			return

	# Turn-based timeout fallback — only advances if the conversation is stuck.
	# State thresholds are ignored: only the LLM's narrative judgment drives progression.
	var thresholds = DramaLoader.get_thresholds(beat)
	for condition in thresholds:
		var parts = condition.split(" ")
		if parts.size() < 3:
			continue
		var variable = parts[0].strip_edges()
		if variable != "turn":
			continue
		var operator = parts[1].strip_edges()
		var value    = int(parts[2].strip_edges())
		var current  = game_state.get(variable, 0)

		var triggered = (operator == ">"  and current >  value) or \
						(operator == ">=" and current >= value)

		if triggered:
			var next = thresholds[condition].strip_edges()
			if next != beat:
				if next == "kicked_out":
					_set_transition(next)
					_trigger_game_over()
					return
				if next.begins_with("ending_") or next == "resolution":
					_set_transition(next)
					_add_line("— SCENE —", _scene_transition, Color.YELLOW)
					_trigger_ending(next)
					return
				_set_transition(next)
			return

func _trigger_game_over():
	Globals.ending_name = "KICKED OUT"
	Globals.ending_text = "Dylan had enough. Before you could say another word, he showed you the door. You're out on the street, the night air cold against your face. Some doors don't open twice."
	Globals.dylan_trust     = game_state.dylan_trust
	Globals.dylan_anxiety   = game_state.dylan_anxiety
	Globals.dylan_tension   = game_state.dylan_tension
	Globals.jasmine_trust   = game_state.jasmine_trust
	Globals.jasmine_anxiety = game_state.jasmine_anxiety
	Globals.jasmine_tension = game_state.jasmine_tension
	get_tree().change_scene_to_file("res://game_over.tscn")

func _trigger_ending(beat_name: String):
	var endings = {
		"ending_honest_growth":
			["HONEST GROWTH",
			"Dylan and Jasmine finally stopped pretending. The conversation was raw and uncomfortable, but something real shifted between them. It wasn't easy — but nothing worthwhile ever is."],
		"ending_false_comfort":
			["FALSE COMFORT",
			"Everyone smiled. Everyone said the right things. But underneath the polite laughter, nothing was truly resolved. The cracks were plastered over, not repaired. They'll hold until the next dinner."],
		"ending_return_to_past":
			["RETURN TO PAST",
			"Old habits won. Dylan and Jasmine slid back into familiar patterns like comfortable, worn-out clothes. Nothing changed — and that was exactly the problem."],
		"ending_toxic_spiral":
			["TOXIC SPIRAL",
			"The evening curdled into something ugly. Accusations flew, old wounds reopened, and the night ended with more damage than anyone could repair. Some relationships don't break all at once — they rot from the inside."],
		"ending_plot_twist":
			["PLOT TWIST",
			"Nothing was what it seemed tonight. The truth that surfaced changed everything the player thought they knew about Dylan, Jasmine, and the life they've built together."],
		"resolution":
			["RESOLUTION",
			"The night reached its natural end. Goodbyes were said at the door. Whatever happens next is between Dylan and Jasmine — the player was just a witness."]
	}
	var data = endings.get(beat_name, ["ENDING", "The night came to a close."])
	Globals.ending_name = data[0]
	Globals.ending_text = data[1]
	Globals.dylan_trust     = game_state.dylan_trust
	Globals.dylan_anxiety   = game_state.dylan_anxiety
	Globals.dylan_tension   = game_state.dylan_tension
	Globals.jasmine_trust   = game_state.jasmine_trust
	Globals.jasmine_anxiety = game_state.jasmine_anxiety
	Globals.jasmine_tension = game_state.jasmine_tension
	get_tree().change_scene_to_file("res://game_over.tscn")

# ── HISTORY COMPRESSION ────────────────────────────────────────────────────────

func _compress_history(last_dialogue: String):
	conversation_history.append({"role": "assistant", "content": last_dialogue})

	if conversation_history.size() > 10:
		var old   = conversation_history.slice(0, conversation_history.size() - 6)
		var pname = Globals.player_name if Globals.player_name != "" else "You"
		var lines = []
		for i in range(0, old.size() - 1, 2):
			if i + 1 < old.size():
				lines.append('%s: "%s" → Dylan: "%s"' % [
					pname,
					old[i].get("content", "").left(60),
					old[i + 1].get("content", "").left(60)
				])
		history_summary = "\n".join(lines)
		conversation_history = conversation_history.slice(
			conversation_history.size() - 6,
			conversation_history.size()
		)

# ── UI HELPERS ─────────────────────────────────────────────────────────────────

func _add_line(speaker: String, text: String, color: Color):
	if not is_inside_tree():
		return
	var label                   = Label.new()
	if speaker == "":
		label.text = text
	else:
		label.text = "[%s]: %s" % [speaker, text]
	label.modulate              = color
	label.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_vbox.add_child(label)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _set_waiting(state: bool):
	waiting               = state
	player_input.editable = not state
	if state:
		var speaker_name = "Dylan" if _last_speaker == "dylan" else "Jasmine"
		status_bar.text = "%s is thinking..." % speaker_name
	else:
		status_bar.text = ""

func _on_prev_char():
	var chars = ["dylan", "jasmine"]
	var idx = chars.find(_viewing_character)
	_viewing_character = chars[(idx - 1 + chars.size()) % chars.size()]
	_update_character_display()
	_update_debug()

func _on_next_char():
	var chars = ["dylan", "jasmine"]
	var idx = chars.find(_viewing_character)
	_viewing_character = chars[(idx + 1) % chars.size()]
	_update_character_display()
	_update_debug()

func _update_character_display():
	var name_str = "Dylan" if _viewing_character == "dylan" else "Jasmine"
	var emo = _char_emotions[_viewing_character]
	char_name.text = name_str
	emotion_label.text = "%s %s" % [EMOJI_MAP.get(emo, "😐"), emo]

func _update_debug():
	var prefix = _viewing_character
	trust_label.text    = "Trust:   %d" % game_state.get(prefix + "_trust",     0)
	anxiety_label.text  = "Anxiety: %d" % game_state.get(prefix + "_anxiety",   0)
	tension_label.text  = "Tension: %d" % game_state.get(prefix + "_tension",   0)
	player_tone_label.text = "Player tone: %s" % _last_player_tone
