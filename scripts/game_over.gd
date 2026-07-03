extends Control

@onready var ending_label:   Label        = $ColorRect/MarginContainer/VBoxContainer/Ending
@onready var ending_text:    RichTextLabel = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/EndingText
@onready var dylan_trust:    Label        = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DylanTrust
@onready var dylan_anxiety:  Label        = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DylanAnxiety
@onready var dylan_tension:  Label        = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DylanTension
@onready var jasmine_trust:    Label      = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/JasmineTrust
@onready var jasmine_anxiety:  Label      = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/JasmineAnxiety
@onready var jasmine_tension:  Label      = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/JasmineTension
@onready var restart_btn:    Button       = $ColorRect/MarginContainer/VBoxContainer/Restart

func _ready():
	ending_label.text = Globals.ending_name
	ending_text.text = "[center]%s[/center]" % Globals.ending_text
	dylan_trust.text = "Trust:   %d" % Globals.dylan_trust
	dylan_anxiety.text = "Anxiety: %d" % Globals.dylan_anxiety
	dylan_tension.text = "Tension: %d" % Globals.dylan_tension
	jasmine_trust.text = "Trust:   %d" % Globals.jasmine_trust
	jasmine_anxiety.text = "Anxiety: %d" % Globals.jasmine_anxiety
	jasmine_tension.text = "Tension: %d" % Globals.jasmine_tension
	restart_btn.pressed.connect(_on_restart)

func _on_restart():
	get_tree().change_scene_to_file("res://main_menu.tscn")
