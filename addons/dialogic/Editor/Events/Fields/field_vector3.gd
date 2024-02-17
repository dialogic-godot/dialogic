@tool
extends DialogicVisualEditorFieldVector

## Event block field for a vector.

var current_value := Vector3()

func _set_value(value:Variant) -> void:
	$X.tooltip_text = tooltip_text
	$Y.tooltip_text = tooltip_text
	$Z.tooltip_text = tooltip_text
	$X.set_value(value.x)
	$Y.set_value(value.y)
	$Z.set_value(value.z)
	current_value = value

func get_value() -> Vector3:
	return current_value
	
func _on_value_changed(property:String, value:float) -> void:
	current_value = Vector3($X.value, $Y.value, $Z.value)
	value_changed.emit(property_name, current_value)
