# npc.gd
# Attach to an Area2D representing a talkable character in the room.
extends Area2D

@export var character_name: String = "dylan"  # "dylan" or "jasmine"
@export var display_name: String = "Dylan"
@export var prompt_offset: Vector2 = Vector2(0, -120)

signal player_entered(npc)
signal player_exited(npc)

@onready var prompt: Label = $PromptLabel

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt:
		prompt.text = "[E] Talk to %s" % display_name
		prompt.visible = false

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_entered.emit(self)
		if prompt:
			prompt.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_exited.emit(self)
		if prompt:
			prompt.visible = false
