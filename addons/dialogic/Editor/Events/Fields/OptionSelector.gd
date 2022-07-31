@tool
extends Control

var property_name : String
signal value_changed

var options : Dictionary
var disabled = false:
	get:
		return disabled
	set(_disabled):
		disabled = _disabled
		$MenuButton.disabled = disabled

func _ready():
	DCSS.style($MenuButton, {
		'border-radius': 3,
		'border-color': Color('#14161A'),
		'border': 1,
		'background': Color('#1D1F25'),
		'padding': [5, 10],
	})
	$MenuButton.about_to_popup.connect(insert_options)
	$MenuButton.get_popup().index_pressed.connect(index_pressed)
	# TODOT godot4 figure this out (popup background panel style) 
	# $MenuButton.get_popup().add_theme_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))

func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = value.is_empty()

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = value.is_empty()

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
