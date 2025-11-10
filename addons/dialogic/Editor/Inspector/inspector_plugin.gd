@tool
extends EditorInspectorPlugin


func _can_handle(object: Object) -> bool:
	return true


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if type == TYPE_OBJECT and hint_type == PROPERTY_HINT_RESOURCE_TYPE:
		if hint_string == "DialogicTimeline":
			var editor: EditorProperty = load("res://addons/dialogic/Editor/Inspector/timeline_inspector_field.gd").new()
			add_property_editor(name, editor)
			return true
	return false
