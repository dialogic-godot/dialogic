@tool
extends DialogicVisualEditorField

## Event block field for editing dictionaries.

const DictionaryValue = "res://addons/dialogic/Editor/Events/Fields/dictionary_part.tscn"

func _ready() -> void:
	%Add.icon = get_theme_icon("Add", "EditorIcons")


func _set_value(value:Variant) -> void:
	for child in get_children():
		if child != %Add:
			child.queue_free()

	var dict: Dictionary

	# attempt to take dictionary values, create a fresh one if not possible
	if typeof(value) == TYPE_DICTIONARY:
		dict = value
	elif typeof(value) == TYPE_STRING:
		if value.begins_with('{'):
			var result: Variant = JSON.parse_string(value)
			if result != null:
				dict = result as Dictionary

	var keys := dict.keys()
	var values := dict.values()

	for index in dict.size():
		var x: Node = load(DictionaryValue).instantiate()
		add_child(x)
		x.set_value(values[index])
		x.set_key(keys[index])
		x.value_changed.connect(recalculate_values)
		move_child(%Add, -1)


func _on_value_changed(value:Variant) -> void:
	value_changed.emit(property_name, value)


func recalculate_values() -> void:
	var dict := {}
	for child in get_children():
		if child != %Add and !child.is_queued_for_deletion():
			dict[child.get_key()] = child.get_value()
	_on_value_changed(dict)


func _on_AddButton_pressed() -> void:
	var x: Control = load(DictionaryValue).instantiate()
	add_child(x)
	x.set_key("")
	x.set_value("")
	x.value_changed.connect(recalculate_values)
	x.focus_key()
	recalculate_values()
	move_child(%Add, -1)
