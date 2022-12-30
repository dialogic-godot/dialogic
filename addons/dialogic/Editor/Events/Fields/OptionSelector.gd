@tool
extends Control

var property_name : String
signal value_changed

var options : Array = []
var disabled = false:
	get:
		return disabled
	set(_disabled):
		disabled = _disabled
		$MenuButton.disabled = disabled
		$MenuButton.focus_mode = FOCUS_NONE

func _ready():
	$MenuButton.add_theme_stylebox_override("normal", get_theme_stylebox("normal", "LineEdit"))
	$MenuButton.add_theme_stylebox_override("hover", get_theme_stylebox("normal", "LineEdit"))
	
	$MenuButton.add_theme_stylebox_override("focus", get_theme_stylebox("focus", "LineEdit"))
	$MenuButton.add_theme_stylebox_override("disabled", get_theme_stylebox("normal", "LineEdit"))
	$MenuButton.add_theme_color_override("font_disabled_color", get_theme_color("font_color", "MenuButton"))
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
	for option in options:
		if option['value'] == value:
			$MenuButton.text = option['label']
			$MenuButton.icon = option.get('icon', load("res://addons/dialogic/Editor/Images/Dropdown/default.svg"))

func get_value():
	return $MenuButton.text

func insert_options():
	$MenuButton.get_popup().clear()
	
	var idx = 0
	for option in options:
		$MenuButton.get_popup().add_icon_item(option.get('icon',load("res://addons/dialogic/Editor/Images/Dropdown/default.svg")), option['label'])
		$MenuButton.get_popup().set_item_metadata(idx, option['value'])
		idx += 1

func index_pressed(idx):
	$MenuButton.text = $MenuButton.get_popup().get_item_text(idx)
	$MenuButton.icon = $MenuButton.get_popup().get_item_icon(idx)
	
	emit_signal("value_changed", property_name, $MenuButton.get_popup().get_item_metadata(idx))
