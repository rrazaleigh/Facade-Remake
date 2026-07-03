# room.gd
# Controller for the explorable dinner-room scene.
extends Node2D

@onready var dialogue_ui: Control = $CanvasLayer/Main
@onready var player: CharacterBody2D = $Player
@onready var interact_label: Label = $CanvasLayer/InteractPrompt

var _near_npc: Node2D = null

func _ready():
	Globals.room_active = true
	
	# Connect every NPC's signals
	for npc in get_tree().get_nodes_in_group("npc"):
		npc.player_entered.connect(_on_npc_entered)
		npc.player_exited.connect(_on_npc_exited)
	
	if dialogue_ui:
		dialogue_ui.set_room(self)
		dialogue_ui.visible = false
	
	if interact_label:
		interact_label.visible = false
	
	var pname = Globals.player_name if Globals.player_name != "" else "Friend"
	if interact_label:
		interact_label.text = "Use A/D or Arrow Keys to move. Press E to talk."
		interact_label.visible = true
		# Fade out the hint after a few seconds
		await get_tree().create_timer(4.0).timeout
		if interact_label:
			interact_label.visible = false

func _process(_delta):
	if _near_npc and Input.is_action_just_pressed("interact"):
		start_dialogue(_near_npc)

func _on_npc_entered(npc: Node2D):
	_near_npc = npc
	if interact_label:
		interact_label.text = "[E] Talk to %s" % npc.display_name
		interact_label.visible = true

func _on_npc_exited(npc: Node2D):
	if _near_npc == npc:
		_near_npc = null
		if interact_label:
			interact_label.visible = false

func start_dialogue(npc: Node2D):
	if not dialogue_ui:
		return
	
	Globals.talking_to = npc.character_name
	player.set_active(false)
	if interact_label:
		interact_label.visible = false
	
	dialogue_ui.visible = true
	dialogue_ui.start_dialogue(npc.character_name)

func end_dialogue():
	Globals.talking_to = ""
	player.set_active(true)
	if dialogue_ui:
		dialogue_ui.visible = false
	if _near_npc and interact_label:
		interact_label.text = "[E] Talk to %s" % _near_npc.display_name
		interact_label.visible = true
