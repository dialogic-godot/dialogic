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
	set_left_text('')
	set_right_text('')

func set_right_text(value:String):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_left_text(value:String):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_value(value):
	for element in options:
		if options[element] == value:
			$MenuButton.text = element

func get_value():
	return $MenuButton.text

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
