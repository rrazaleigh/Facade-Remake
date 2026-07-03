extends Node

var player_name: String = ""

# Exploration / dialogue flow
var talking_to: String = ""        # "dylan", "jasmine", or "" for free roam
var room_active: bool = false      # true when the room scene is running

# Ending state (set by main.gd before changing to game_over)
var ending_name:     String = ""
var ending_text:     String = ""
var dylan_trust:     int = 0
var dylan_anxiety:   int = 0
var dylan_tension:   int = 0
var jasmine_trust:   int = 0
var jasmine_anxiety: int = 0
var jasmine_tension: int = 0
