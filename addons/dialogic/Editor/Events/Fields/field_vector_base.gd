class_name DialogicVisualEditorFieldVector
extends DialogicVisualEditorField
## Base type for Vector event blocks


func _ready() -> void:
	for child in get_children():
		child.tooltip_text = tooltip_text
		child.property_name = child.name #to identify the name of the changed sub-component
		child.value_changed.connect(_on_sub_value_changed)


func _load_display_info(info: Dictionary) -> void:
	for child in get_children():
		if child is DialogicVisualEditorFieldNumber:
			if info.get('no_prefix', false):
				child._load_display_info(info)
			else:
				var prefixed_info := info.duplicate()
				prefixed_info.merge({'prefix':child.name.to_lower()})
				child._load_display_info(prefixed_info)


func _set_value(value: Variant) -> void:
	_update_sub_component_text(value)
	_on_value_changed(value)


func _on_value_changed(value: Variant) -> void:
	value_changed.emit(property_name, value)


func _on_sub_value_changed(sub_component: String, value: float) -> void:
	pass


func _update_sub_component_text(value: Variant) -> void:
	pass
