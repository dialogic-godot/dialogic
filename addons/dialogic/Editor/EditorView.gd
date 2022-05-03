tool
extends Control

onready var timeline_editor = $MarginContainer/VBoxContainer/TimelineEditor

func _ready():
	$MarginContainer/VBoxContainer/Toolbar/Settings.connect("button_up", self, "show_settings")
	set_current_margin($MarginContainer, get_constant("separation", "BoxContainer") - 1)


func edit_timeline(object):
	timeline_editor.load_timeline(object)


func set_current_margin(node, separation):
	node.margin_top = separation
	node.margin_left = separation
	node.margin_right = separation * -1
	node.margin_bottom = separation * -1

func show_settings():
	$SettingsEditor.popup_centered()
