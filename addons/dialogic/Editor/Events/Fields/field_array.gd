@tool
extends DialogicVisualEditorField

## Event block field for editing arrays.


const ArrayValue := "res://addons/dialogic/Editor/Events/Fields/array_part.tscn"


func _ready():
	%Add.icon = get_theme_icon("Add", "EditorIcons")
	%Add.pressed.connect(_on_AddButton_pressed)


func _set_value(value:Variant) -> void:
	value = value as Array
	for child in get_children():
		if child != %Add:
			child.queue_free()

	for item in value:
		var x: Node = load(ArrayValue).instantiate()
		add_child(x)
		x.set_value(item)
		x.value_changed.connect(recalculate_values)
		move_child(%Add, -1)


func _on_value_changed(value:Variant) -> void:
	value_changed.emit(property_name, value)


func recalculate_values() -> void:
	var arr := []
	for child in get_children():
		if child != %Add and !child.is_queued_for_deletion():
			arr.append(child.get_value())
	_on_value_changed(arr)


func _on_AddButton_pressed() -> void:
	var x :Control = load(ArrayValue).instantiate()
	add_child(x)
	x.set_value("")
	x.value_changed.connect(recalculate_values)
	recalculate_values()
	move_child(%Add, -1)

