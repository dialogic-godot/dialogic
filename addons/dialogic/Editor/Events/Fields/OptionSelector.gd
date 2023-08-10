@tool
extends MenuButton

## Event block field for constant options. For varying options use ComplexPicker.

signal value_changed
var property_name : String

var options : Array = []

## if true, only the symbol will be displayed. In the dropdown text will be visible.
## Useful for making UI simpler
var symbol_only := false:
	set(value):
		symbol_only = value
		if value: text = ""

var current_value :Variant = -1

func _ready() -> void:
#	add_theme_stylebox_override("normal", get_theme_stylebox("normal", "LineEdit"))
#	add_theme_stylebox_override("hover", get_theme_stylebox("normal", "LineEdit"))
	
#	add_theme_stylebox_override("focus", get_theme_stylebox("focus", "LineEdit"))
#	add_theme_stylebox_override("disabled", get_theme_stylebox("normal", "LineEdit"))
	add_theme_color_override("font_disabled_color", get_theme_color("font_color", "MenuButton"))
	about_to_popup.connect(insert_options)
	get_popup().index_pressed.connect(index_pressed)


func set_value(value) -> void:
	for option in options:
		if option['value'] == value:
			if typeof(option.get('icon')) == TYPE_ARRAY:
				option.icon = callv('get_theme_icon', option.get('icon'))
			if !symbol_only:
				text = option['label']
			icon = option.get('icon', null)
			current_value = value


func get_value() -> Variant:
	return current_value


func insert_options() -> void:
	get_popup().clear()
	
	var idx := 0
	for option in options:
		if typeof(option.get('icon')) == TYPE_ARRAY:
			option.icon = callv('get_theme_icon', option.get('icon'))
		get_popup().add_icon_item(option.get('icon', null), option['label'])
		get_popup().set_item_metadata(idx, option['value'])
		idx += 1


func index_pressed(idx:int) -> void:
	current_value = idx
	if !symbol_only: 
		text = get_popup().get_item_text(idx)
	icon = get_popup().get_item_icon(idx)
	value_changed.emit(property_name, get_popup().get_item_metadata(idx))
