@tool
extends VBoxContainer

const ArrayValue = "res://addons/dialogic/Editor/Events/Fields/ArrayValue.tscn"

var property_name : String
signal value_changed


func set_value(value:Array):
	for child in $'%Values'.get_children():
		child.queue_free()
	
	for item in value:
		var x = load(ArrayValue).instanciate()
		$'%Values'.add_child(x)
		x.set_value(item)
		x.value_changed.connect(recalculate_values)

func _on_value_changed(value):
	emit_signal("value_changed", property_name, value)

func recalculate_values():
	var arr = []
	for child in $'%Values'.get_children():
		if !child.is_queued_for_deletion():
			arr.append(child.get_value())
	_on_value_changed(arr)


func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = bool(value)

func set_left_text(value):
	$'%LeftText'.text = str(value)
	$'%LeftText'.visible = bool(value)

func _on_AddButton_pressed():
	var x = load(ArrayValue).instanciate()
	$'%Values'.add_child(x)
	x.set_value("")
	x.connect('value_changed', self, "recalculate_values")
	recalculate_values()
