extends Control

const API_URL = "http://127.0.0.1:11434/api/chat"
const MODEL   = "llama3.2:3b"

@onready var history_vbox  : VBoxContainer   = $MarginContainer/VBoxContainer/HBoxContainer/Dialogue/DialogueHistory/HistoryVBox
@onready var scroll        : ScrollContainer = $MarginContainer/VBoxContainer/HBoxContainer/Dialogue/DialogueHistory
@onready var player_input  : LineEdit        = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/InputRow/VBoxContainer/PlayerInput
@onready var status_bar    : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/InputRow/VBoxContainer/StatusBar
@onready var char_name     : Label           = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Characters/CharacterName
@onready var emotion_label : Label           = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Characters/EmotionLabel
@onready var state_label1  : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CenterContainer/StateDebug/StateLabel1
@onready var state_label2  : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CenterContainer/StateDebug/StateLabel2
@onready var state_label3  : Label           = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CenterContainer/StateDebug/StateLabel3
@onready var player_tone_label: Label        = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/InputRow/VBoxContainer/ToneLabel
@onready var http          : HTTPRequest     = $HTTPRequest
@onready var prev_char_btn : Button          = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Switch
@onready var next_char_btn : Button          = $MarginContainer/VBoxContainer/HBoxContainer/Character/VBoxContainer/VBoxContainer/HBoxContainer/Switch2

@onready var debug_window          : Window       = $Window
@onready var beat_option           : OptionButton = $Window/VBoxContainer/BeatHBox/BeatOptionButton
@onready var set_beat_btn          : Button       = $Window/VBoxContainer/BeatHBox/SetBeatButton
@onready var dylan_mask_sb         : SpinBox      = $Window/VBoxContainer/DylanMask/DylanMaskSpinBox
@onready var dylan_anxiety_sb      : SpinBox      = $Window/VBoxContainer/DylanAnxiety/DylanAnxietySpinBox
@onready var dylan_attachment_sb   : SpinBox      = $Window/VBoxContainer/DylanAttachment/DylanAttachmentSpinBox
@onready var dylan_trust_sb        : SpinBox      = $Window/VBoxContainer/DylanTrust/DylanTrustSpinBox
@onready var dylan_hope_sb         : SpinBox      = $Window/VBoxContainer/DylanHope/DylanHopeSpinBox
@onready var dylan_hostility_sb    : SpinBox      = $Window/VBoxContainer/DylanHostility/DylanHostilitySpinBox
@onready var jasmine_suspicion_sb  : SpinBox      = $Window/VBoxContainer/JasmineSuspicion/JasmineSuspicionSpinBox
@onready var jasmine_patience_sb   : SpinBox      = $Window/VBoxContainer/JasminePatience/JasminePatienceSpinBox
@onready var jasmine_trust_sb      : SpinBox      = $Window/VBoxContainer/JasmineTrust/JasmineTrustSpinBox
@onready var ending_option         : OptionButton = $Window/VBoxContainer/EndingHBox/EndingOptionButton
@onready var trigger_end_btn       : Button       = $Window/VBoxContainer/EndingHBox/TriggerEndingButton
@onready var close_debug_btn       : Button       = $Window/VBoxContainer/CloseButton

var game_state = {
	"dylan_mask":          70,
	"dylan_anxiety":       30,
	"dylan_attachment":    60,
	"dylan_trust":         50,
	"dylan_hope":          40,
	"dylan_hostility":     10,
	"jasmine_suspicion":   20,
	"jasmine_patience":    60,
	"jasmine_trust":       50,
	"current_beat":        "arrival",
	"turn":                0
}

var conversation_history : Array  = []
var history_summary      : String = ""
var waiting              : bool   = false
var _pending_user_index  : int   = -1
var _game_over           : bool   = false
var _last_player_intent   : String = "neutral"
var _scene_transition    : String = ""
var _continue_count      : int   = 0
var _narrative_log       : Array = []
var _last_speaker        : String = "dylan"
var _viewing_character   : String = "dylan"
var _char_emotions       : Dictionary = {"dylan": "neutral", "jasmine": "neutral"}

const MAX_CONSECUTIVE    : int   = 3
const BEAT_ORDER = [
	"arrival", "small_talk", "no_drama", "cracks_showing",
	"jasmine_feels_it", "hostile_undercurrents", "hostile_escalation",
	"confession", "personal_growth",
	"ending_normal_night", "ending_jasmine_leaves", "ending_new_beginnings",
	"ending_return_to_past", "ending_toxic_spiral", "ending_honest_growth",
	"ending_plot_twist", "ending_dark", "game_over_kicked_out"
]

const DYLAN_LABELS = ["Mask", "Anxiety", "Attachment"]
const DYLAN_KEYS   = ["dylan_mask", "dylan_anxiety", "dylan_attachment"]
const JASMINE_LABELS = ["Suspicion", "Patience", "Trust"]
const JASMINE_KEYS   = ["jasmine_suspicion", "jasmine_patience", "jasmine_trust"]

const EMOJI_MAP = {
	"neutral":    "😐",
	"warm":       "😊",
	"defensive":  "😤",
	"hostile":    "😠",
	"anxious":    "😰",
	"vulnerable": "🥺"
}

func _ready():
	print("Using Ollama at ", API_URL)

	http.request_completed.connect(_on_response)
	player_input.text_submitted.connect(_on_send)
	prev_char_btn.pressed.connect(_on_prev_char)
	next_char_btn.pressed.connect(_on_next_char)

	for b in BEAT_ORDER:
		beat_option.add_item(b)
	beat_option.select(BEAT_ORDER.find(game_state.current_beat))
	for e in ["ending_normal_night", "ending_jasmine_leaves", "ending_new_beginnings", "ending_return_to_past", "ending_toxic_spiral", "ending_honest_growth", "ending_plot_twist", "ending_dark"]:
		ending_option.add_item(e)
	set_beat_btn.pressed.connect(_on_debug_set_beat)
	dylan_mask_sb.value_changed.connect(_on_debug_state_changed.bind("dylan_mask"))
	dylan_anxiety_sb.value_changed.connect(_on_debug_state_changed.bind("dylan_anxiety"))
	dylan_attachment_sb.value_changed.connect(_on_debug_state_changed.bind("dylan_attachment"))
	dylan_trust_sb.value_changed.connect(_on_debug_state_changed.bind("dylan_trust"))
	dylan_hope_sb.value_changed.connect(_on_debug_state_changed.bind("dylan_hope"))
	dylan_hostility_sb.value_changed.connect(_on_debug_state_changed.bind("dylan_hostility"))
	jasmine_suspicion_sb.value_changed.connect(_on_debug_state_changed.bind("jasmine_suspicion"))
	jasmine_patience_sb.value_changed.connect(_on_debug_state_changed.bind("jasmine_patience"))
	jasmine_trust_sb.value_changed.connect(_on_debug_state_changed.bind("jasmine_trust"))
	trigger_end_btn.pressed.connect(_on_debug_trigger_ending)
	close_debug_btn.pressed.connect(_on_debug_close)
	debug_window.visibility_changed.connect(_sync_debug_menu)

	_update_character_display()
	_update_debug()
	var pname = Globals.player_name
	_add_line("SCENE", "Dylan and Jasmine invited %s over for dinner. Dylan greets %s at the door; Jasmine is in the kitchen cooking." % [pname, pname], Color.YELLOW)
	status_bar.text = "Type something to begin..."

func _input(event):
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
		debug_window.visible = not debug_window.visible
		if debug_window.visible:
			_sync_debug_menu()

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

	var is_action = msg.length() > 1 and msg.begins_with("*") and msg.ends_with("*")
	if is_action:
		_add_line(pname, msg, Color.DIM_GRAY)
	else:
		_add_line(pname, msg, Color.CYAN)

	conversation_history.append({"role": "user", "content": msg})
	_pending_user_index = conversation_history.size() - 1
	_call_llm()

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

func _on_debug_set_beat():
	var beat = BEAT_ORDER[beat_option.selected]
	var dir = DramaLoader.get_directive(beat)
	if dir != "":
		game_state.current_beat = beat
		_add_line("— SCENE —", dir, Color.YELLOW)
		_update_debug()
	else:
		_add_line("DEBUG", "Unknown beat: %s" % beat, Color.RED)

func _on_debug_state_changed(value: float, key: String):
	game_state[key] = clampi(int(value), 0, 100)
	_update_debug()

func _on_debug_trigger_ending():
	var text = ending_option.get_item_text(ending_option.selected)
	_handle_debug_command("!ending=" + text)

func _on_debug_close():
	debug_window.visible = false

func _sync_debug_menu():
	if not debug_window.visible:
		return
	dylan_mask_sb.set_value_no_signal(game_state.dylan_mask)
	dylan_anxiety_sb.set_value_no_signal(game_state.dylan_anxiety)
	dylan_attachment_sb.set_value_no_signal(game_state.dylan_attachment)
	dylan_trust_sb.set_value_no_signal(game_state.dylan_trust)
	dylan_hope_sb.set_value_no_signal(game_state.dylan_hope)
	dylan_hostility_sb.set_value_no_signal(game_state.dylan_hostility)
	jasmine_suspicion_sb.set_value_no_signal(game_state.jasmine_suspicion)
	jasmine_patience_sb.set_value_no_signal(game_state.jasmine_patience)
	jasmine_trust_sb.set_value_no_signal(game_state.jasmine_trust)
	var idx = BEAT_ORDER.find(game_state.current_beat)
	if idx != -1:
		beat_option.select(idx)

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
	var last_intent = _last_player_intent
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

=== PLAYER INTENT CLASSIFIER ===
Silently evaluate the player's message in three stages:
1. INTENT — what is the player trying to do
2. TARGET — who is the player referencing
3. INTENSITY — how strongly is this expressed

Use these to determine state_delta values. This is how the player
is treating you right now.

{tones}

=== CURRENT SCENE CONTEXT ===
BEAT: {beat}
DIRECTIVE: {directive}
PLAYER NAME: {player_name}

EMOTIONAL STATE:
  Dylan:  mask={dm}  anxiety={da}  attachment={dat}  trust={dt}  hope={dh}  hostility={dho}
  Jasmine: suspicion={js}  patience={jp}  trust={jt}

LAST PLAYER INTENT: {last_intent}
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
  "state_delta":  {{"dylan_trust": -2, "dylan_anxiety": 3}} (only include variables that change; all others default to 0 — do not add variables with 0 value),
  "drama_signal":    "none | escalate | beat_complete | continue | game_over",
  "player_intent":   "hostile | guilty | defensive | probing | supportive | curious | dismissive | neutral — the resolved intent after precedence + confidence rules",
  "narrative_moment": "a short phrase describing what happened this turn (e.g. 'dylan_deflected', 'jasmine_probed', 'player_showed_support', 'tension_rose'). Be specific to the scene."
}}

ACTIONS: Use the "action" field for physical actions or non-verbal reactions. Actions will be displayed as *action text*. If there is both an action and dialogue, the action is shown first, then the character speaks. Never put action text inside the "dialogue" field.

PLAYER ACTIONS: If the player types something wrapped in *asterisks*, it is an action (e.g. "*grabs a drink*"). Treat it as something they did, not something they said.

CONTINUE: Use "drama_signal": "continue" only when another character has something meaningful to add, or when your current response genuinely needs a follow-up. Never use "continue" to repeat yourself, add filler, or say the same thing in different words. If you have nothing new to contribute, signal "none" and let the player speak.

NARRATIVE: Use "narrative_moment" to tag what story development occurred each turn. The STORY SO FAR section shows the arc of the conversation.

BEAT PROGRESSION: You control when the scene advances. Signal "beat_complete" when the current beat has run its course — when the key story beat has landed, the tension has shifted, or the conversation has naturally reached a new phase. Do not advance too quickly: let each beat breathe. But do not linger once the moment has passed. Trust your judgment as a storyteller.

IMPORTANT: If the current beat starts with "ending_" or is "game_over_kicked_out", the story is concluding. Write a final, fitting exchange that closes the scene naturally. The game will end after this response.""".format({
		"dylan_per":   dylan_per,
		"jasmine_per": jasmine_per,
		"tones":       tones,
		"beat":        beat,
		"directive":   directive,
		"dm":          game_state.dylan_mask,
		"da":          game_state.dylan_anxiety,
		"dat":         game_state.dylan_attachment,
		"dt":          game_state.dylan_trust,
		"dh":          game_state.dylan_hope,
		"dho":         game_state.dylan_hostility,
		"js":          game_state.jasmine_suspicion,
		"jp":          game_state.jasmine_patience,
		"jt":          game_state.jasmine_trust,
		"last_intent": last_intent,
		"summary":     history_summary if history_summary != "" else "The evening has just started.",
		"present":     present,
		"transition":  transition,
		"narrative":   narrative,
		"player_name": Globals.player_name
	})

func _build_ollama_messages() -> Array:
	var messages = [{"role": "system", "content": _build_system_prompt()}]
	messages.append_array(conversation_history.slice(
		max(0, conversation_history.size() - 8),
		conversation_history.size()
	))
	return messages

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

				if content.begins_with("```"):
					var start = content.find("\n", 3)
					if start != -1:
						content = content.substr(start + 1)
						var end = content.rfind("```")
						if end != -1:
							content = content.substr(0, end)
					else:
						content = content.trim_prefix("```").rstrip("`")
					content = content.strip_edges()

				var npc = JSON.parse_string(content)
				if npc == null:
					_add_line("Dylan", content, Color.WHITE)
				else:
					_apply_response(npc)
					return

	if failed and _pending_user_index != -1:
		conversation_history.remove_at(_pending_user_index)
		_pending_user_index = -1

func _apply_response(r: Dictionary):
	_scene_transition = ""
	var dialogue = r.get("dialogue", "...")
	var emotion  = r.get("emotion",  "neutral")
	var speaker  = r.get("speaker",  "dylan")

	var speaker_name = "Dylan" if speaker == "dylan" else "Jasmine"
	var char_color = Color.WHITE if speaker == "dylan" else Color.LIGHT_PINK

	var action = r.get("action", "")
	if action != null and action != "":
		_add_line("", "*" + action + "*", char_color)

	_add_line(speaker_name, dialogue, char_color)

	_last_speaker = speaker
	_char_emotions[speaker] = emotion
	_viewing_character = speaker
	_update_character_display()

	_last_player_intent = r.get("player_intent", "neutral")

	var delta = r.get("state_delta", {})
	game_state.dylan_mask        = clamp(game_state.dylan_mask       + int(delta.get("dylan_mask",        0)), 0, 100)
	game_state.dylan_anxiety     = clamp(game_state.dylan_anxiety    + int(delta.get("dylan_anxiety",      0)), 0, 100)
	game_state.dylan_attachment  = clamp(game_state.dylan_attachment + int(delta.get("dylan_attachment",   0)), 0, 100)
	game_state.dylan_trust       = clamp(game_state.dylan_trust      + int(delta.get("dylan_trust",        0)), 0, 100)
	game_state.dylan_hope        = clamp(game_state.dylan_hope       + int(delta.get("dylan_hope",         0)), 0, 100)
	game_state.dylan_hostility   = clamp(game_state.dylan_hostility  + int(delta.get("dylan_hostility",    0)), 0, 100)
	game_state.jasmine_suspicion = clamp(game_state.jasmine_suspicion+ int(delta.get("jasmine_suspicion",  0)), 0, 100)
	game_state.jasmine_patience  = clamp(game_state.jasmine_patience + int(delta.get("jasmine_patience",   0)), 0, 100)
	game_state.jasmine_trust     = clamp(game_state.jasmine_trust    + int(delta.get("jasmine_trust",      0)), 0, 100)
	game_state.turn += 1

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
	if signal_val == "game_over" or game_state.dylan_hostility >= 95 or game_state.jasmine_patience <= 5 or game_state.dylan_trust <= 5:
		_compress_history(dialogue, speaker)
		if signal_val == "game_over":
			_trigger_game_over()
		elif game_state.dylan_hostility >= 95:
			_trigger_game_over("KICKED OUT", "Dylan had enough. The hostility in the room was suffocating. Before you could say another word, he showed you the door. Some doors don't open twice.")
		elif game_state.dylan_trust <= 5:
			_trigger_game_over("TRUST BROKEN", "Dylan doesn't trust you anymore. Whatever connection you once had, it's gone now. He looks at you like a stranger, and the night can't end soon enough.")
		else:
			_trigger_game_over("PATIENCE EXHAUSTED", "Jasmine's patience finally ran out. She saw enough, felt enough. The evening ended not with a fight, but with quiet resignation.")
		return

	_advance_drama(signal_val)
	_compress_history(dialogue, speaker)

	if signal_val == "continue" and _continue_count < MAX_CONSECUTIVE:
		_continue_count += 1
		_call_llm()
		return

	_continue_count = 0

func _set_transition(next_beat: String):
	_scene_transition = DramaLoader.get_directive(next_beat)
	game_state.current_beat = next_beat

func _advance_drama(signal_val: String):
	var beat = game_state.current_beat

	if signal_val in ["beat_complete", "escalate"]:
		var idx = BEAT_ORDER.find(beat)
		if idx != -1 and idx < BEAT_ORDER.size() - 1:
			var next = BEAT_ORDER[idx + 1]
			if next.begins_with("ending_") or next == "game_over_kicked_out":
				_set_transition(next)
				_add_line("— SCENE —", _scene_transition, Color.YELLOW)
				_trigger_ending(next)
				return
			_set_transition(next)
			return
		elif beat == "game_over_kicked_out":
			_trigger_game_over()
			return

func _trigger_game_over(ending_name := "KICKED OUT", ending_text := ""):
	if ending_text == "":
		ending_text = "Dylan had enough. Before you could say another word, he showed you the door. You're out on the street, the night air cold against your face. Some doors don't open twice."
	Globals.ending_name = ending_name
	Globals.ending_text = ending_text
	Globals.dylan_mask       = game_state.dylan_mask
	Globals.dylan_anxiety    = game_state.dylan_anxiety
	Globals.dylan_attachment = game_state.dylan_attachment
	Globals.dylan_trust      = game_state.dylan_trust
	Globals.dylan_hope       = game_state.dylan_hope
	Globals.dylan_hostility  = game_state.dylan_hostility
	Globals.jasmine_suspicion = game_state.jasmine_suspicion
	Globals.jasmine_patience  = game_state.jasmine_patience
	Globals.jasmine_trust     = game_state.jasmine_trust
	get_tree().change_scene_to_file("res://game_over.tscn")

func _trigger_ending(beat_name: String):
	var endings = {
		"ending_normal_night":
			["NORMAL NIGHT",
			"The evening was pleasant. Everyone smiled, everyone ate, everyone said goodbye. Nothing was confronted, nothing was resolved. The tension stayed buried where no one had to look at it."],
		"ending_jasmine_leaves":
			["JASMINE LEAVES",
			"Jasmine finally understood. She didn't shout or cry — she just quietly removed herself from the equation. She deserved more than being someone's second choice, and she knew it. Dylan was left alone with what he'd done."],
		"ending_new_beginnings":
			["NEW BEGINNINGS",
			"Dylan accepted that neither Becca nor his past defines him anymore. He ended things with Jasmine respectfully and began the long, uncertain work of rebuilding his life. Hopeful, but bittersweet."],
		"ending_return_to_past":
			["RETURN TO PAST",
			"Dylan convinced himself Becca was still the answer. He left Jasmine, already composing the message in his head. Whether she'd take him back was a question the night refused to answer."],
		"ending_toxic_spiral":
			["TOXIC SPIRAL",
			"Dylan stayed with Jasmine for comfort while clinging to Becca in his heart. The lies grew smoother, the guilt quieter. The player walked away knowing they'd watched someone choose the easy wound over the hard truth."],
		"ending_honest_growth":
			["HONEST GROWTH",
			"Dylan admitted everything. Jasmine didn't forgive him — not yet. But for the first time, there was honesty between them. Hope existed, fragile and real. Nothing was fixed. But nothing was fake anymore."],
		"ending_plot_twist":
			["PLOT TWIST",
			"In the middle of the conversation, Dylan stumbled onto a question he'd never asked himself: were his feelings for Becca ever real, or just the safest thing he knew? He didn't have the answer. But he finally started looking for it."],
		"ending_dark":
			["DARK ENDING",
			"After the player left, Dylan sat alone in the quiet apartment. The weight of everything he'd been running from finally caught up. There were no goodbyes, no dramatic gestures — just a silence that would last forever."]
	}
	var data = endings.get(beat_name, ["ENDING", "The night came to a close."])
	Globals.ending_name = data[0]
	Globals.ending_text = data[1]
	Globals.dylan_mask       = game_state.dylan_mask
	Globals.dylan_anxiety    = game_state.dylan_anxiety
	Globals.dylan_attachment = game_state.dylan_attachment
	Globals.dylan_trust      = game_state.dylan_trust
	Globals.dylan_hope       = game_state.dylan_hope
	Globals.dylan_hostility  = game_state.dylan_hostility
	Globals.jasmine_suspicion = game_state.jasmine_suspicion
	Globals.jasmine_patience  = game_state.jasmine_patience
	Globals.jasmine_trust     = game_state.jasmine_trust
	get_tree().change_scene_to_file("res://game_over.tscn")

func _compress_history(last_dialogue: String, speaker: String = "dylan"):
	conversation_history.append({"role": "assistant", "speaker": speaker, "content": last_dialogue})

	if conversation_history.size() > 10:
		var old   = conversation_history.slice(0, conversation_history.size() - 6)
		var pname = Globals.player_name if Globals.player_name != "" else "You"
		var lines = []
		for i in range(0, old.size() - 1, 2):
			if i + 1 < old.size():
				var spk = old[i + 1].get("speaker", "dylan")
				var spk_name = "Dylan" if spk == "dylan" else "Jasmine"
				lines.append('%s: "%s" → %s: "%s"' % [
					pname,
					old[i].get("content", "").left(60),
					spk_name,
					old[i + 1].get("content", "").left(60)
				])
		history_summary = "\n".join(lines)
		conversation_history = conversation_history.slice(
			conversation_history.size() - 6,
			conversation_history.size()
		)

	var excess = history_vbox.get_child_count() - 40
	if excess > 0:
		for j in range(min(excess, 10)):
			var child = history_vbox.get_child(0)
			history_vbox.remove_child(child)
			child.queue_free()

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
	var labels = DYLAN_LABELS if _viewing_character == "dylan" else JASMINE_LABELS
	var keys   = DYLAN_KEYS   if _viewing_character == "dylan" else JASMINE_KEYS
	state_label1.text = "%s: %d" % [labels[0], game_state.get(keys[0], 0)]
	state_label2.text = "%s: %d" % [labels[1], game_state.get(keys[1], 0)]
	state_label3.text = "%s: %d" % [labels[2], game_state.get(keys[2], 0)]
	player_tone_label.text = "Player intent: %s" % _last_player_intent
	if debug_window.visible:
		_sync_debug_menu()
