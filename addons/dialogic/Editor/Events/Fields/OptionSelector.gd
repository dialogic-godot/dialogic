tool
extends Control

var property_name : String
signal value_changed

var options : Dictionary
var disabled = false setget set_disabled

func _ready():
	DCSS.style($MenuButton, {
		'border-radius': 3,
		'border-color': '#14161A',
		'border': 1,
		'background': '#1D1F25',
		'padding': [5, 10],
	})
	$MenuButton.connect("about_to_show", self,  'insert_options')
	$MenuButton.get_popup().connect("index_pressed", self,  'index_pressed')
	$MenuButton.get_popup().add_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))

func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = bool(value)

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = bool(value)

func set_value(value):
	for element in options:
		if options[element] == value:
			$MenuButton.text = element


func insert_options():
	$MenuButton.get_popup().clear()
	
	var idx = 0
	for option in options:
		$MenuButton.get_popup().add_item(option)
		$MenuButton.get_popup().set_item_metadata(idx, options[option])
		idx += 1

func index_pressed(idx):
	$MenuButton.text = $MenuButton.get_popup().get_item_text(idx)
	
	emit_signal("value_changed", property_name, $MenuButton.get_popup().get_item_metadata(idx))

func set_disabled(_disabled):
	disabled = _disabled
	$MenuButton.disabled = disabled
