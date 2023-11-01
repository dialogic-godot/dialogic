@tool
extends VBoxContainer

## Event block field for editing arrays. 

signal value_changed
var property_name : String

const PairValue = "res://addons/dialogic/Editor/Events/Fields/KeyValuePairValue.tscn"

func _ready():
	%Add.icon = get_theme_icon("Add", "EditorIcons")

func set_value(value) -> void:
	for child in %Values.get_children():
		child.queue_free()
	
	var dict : Dictionary
	
	# attempt to take dictionary values, create a fresh one if not possible
	if typeof(value) == TYPE_DICTIONARY:
		dict = value
	elif typeof(value) == TYPE_STRING:
		if value.begins_with('{'):
			var result = JSON.parse_string(value)
			if result != null:
				dict = result as Dictionary
			else:
				dict = Dictionary()
		else:
			dict = Dictionary()
	
	var keys := dict.keys()
	var values := dict.values()
	
	for index in dict.size():
		var x :Node = load(PairValue).instantiate()
		%Values.add_child(x)
		x.set_key(keys[index])
		x.set_value(values[index])
		x.value_changed.connect(recalculate_values)


func _on_value_changed(value:Variant) -> void:
	emit_signal("value_changed", property_name, value)


func recalculate_values() -> void:
	var dict := {}
	for child in %Values.get_children():
		if !child.is_queued_for_deletion():
			dict[child.get_key()] = child.get_value()
	_on_value_changed(dict)


func _on_AddButton_pressed() -> void:
	var x :Control = load(PairValue).instantiate()
	%Values.add_child(x)
	x.set_key("")
	x.set_value("")
	x.value_changed.connect(recalculate_values)
	recalculate_values()


## Overridable
func set_left_text(value:String) -> void:
	%LeftText.text = str(value)
	%LeftText.visible = value.is_empty()

