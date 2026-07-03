extends Control

@onready var name_input: LineEdit = $ColorRect/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var start_btn: Button = $ColorRect/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/Button

func _ready():
	start_btn.pressed.connect(_on_start)
	name_input.text_submitted.connect(func(_t): _on_start())

func _on_start():
	var name = name_input.text.strip_edges()
	if name == "":
		name = "Friend"
	Globals.player_name = name
	get_tree().change_scene_to_file("res://main.tscn")
