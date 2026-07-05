extends Control

@onready var ending_label:   Label        = $ColorRect/MarginContainer/VBoxContainer/Ending
@onready var ending_text:    RichTextLabel = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/EndingText
@onready var dylan_mask:     Label        = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DylanMask
@onready var dylan_anxiety:  Label        = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DylanAnxiety
@onready var dylan_attachment: Label      = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DylanAttachment
@onready var jasmine_suspicion: Label     = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/JasmineSuspicion
@onready var jasmine_patience: Label      = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/JasminePatience
@onready var jasmine_trust:   Label       = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/JasmineTrust
@onready var restart_btn:    Button       = $ColorRect/MarginContainer/VBoxContainer/Restart

func _ready():
	ending_label.text = Globals.ending_name
	ending_text.text = "[center]%s[/center]" % Globals.ending_text
	dylan_mask.text = "Mask:       %d" % Globals.dylan_mask
	dylan_anxiety.text = "Anxiety:    %d" % Globals.dylan_anxiety
	dylan_attachment.text = "Attachment: %d" % Globals.dylan_attachment
	jasmine_suspicion.text = "Suspicion:  %d" % Globals.jasmine_suspicion
	jasmine_patience.text = "Patience:   %d" % Globals.jasmine_patience
	jasmine_trust.text = "Trust:      %d" % Globals.jasmine_trust
	restart_btn.pressed.connect(_on_restart)

func _on_restart():
	get_tree().change_scene_to_file("res://main_menu.tscn")
