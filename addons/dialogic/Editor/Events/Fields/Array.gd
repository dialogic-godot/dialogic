@tool
extends VBoxContainer

## Event block field for editing arrays. 

signal value_changed
var property_name : String

const ArrayValue = "res://addons/dialogic/Editor/Events/Fields/ArrayValue.tscn"


func set_value(value:Array) -> void:
	for child in %Values.get_children():
		child.queue_free()
	
	for item in value:
		var x = load(ArrayValue).instantiate()
		%Values.add_child(x)
		x.set_value(item)
		x.value_changed.connect(recalculate_values)


func _on_value_changed(value:Variant) -> void:
	emit_signal("value_changed", property_name, value)


func recalculate_values() -> void:
	var arr := []
	for child in %Values.get_children():
		if !child.is_queued_for_deletion():
			arr.append(child.get_value())
	_on_value_changed(arr)


func _on_AddButton_pressed() -> void:
	var x :Control = load(ArrayValue).instantiate()
	%Values.add_child(x)
	x.set_value("")
	x.value_changed.connect(recalculate_values)
	recalculate_values()


## Overridable
func set_left_text(value:String) -> void:
	%LeftText.text = str(value)
	%LeftText.visible = value.is_empty()

