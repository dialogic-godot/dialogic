@tool
extends DialogicVisualEditorFieldVector
## Event block field for a Vector3.

var current_value := Vector3()


func _set_value(value: Variant) -> void:
	current_value = value
	super(value)


func get_value() -> Vector3:
	return current_value


func _on_sub_value_changed(sub_component: String, value: float) -> void:
	match sub_component:
		'X': current_value.x = value
		'Y': current_value.y = value
		'Z': current_value.z = value
	_on_value_changed(current_value)


func _update_sub_component_text(value: Variant) -> void:
	$X._on_value_text_submitted(str(value.x), true)
	$Y._on_value_text_submitted(str(value.y), true)
	$Z._on_value_text_submitted(str(value.z), true)
