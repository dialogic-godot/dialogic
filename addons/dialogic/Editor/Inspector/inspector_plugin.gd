@tool
extends EditorInspectorPlugin

var style_exposed_props := []


func _can_handle(_object: Object) -> bool:
	return true


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	## Handle the Timeline Picker field for DialogicTimeline properties
	if type == TYPE_OBJECT and hint_type == PROPERTY_HINT_RESOURCE_TYPE:
		if hint_string == "DialogicTimeline":
			var editor: EditorProperty = load("res://addons/dialogic/Editor/Inspector/timeline_inspector_field.gd").new()
			add_property_editor(name, editor)
			return true

	## Handle the Style override indicators for style layout scenes.
	if not object is Node:
		return false

	if name in style_exposed_props:
		var l := Control.new()
		add_custom_control(l)
		l.ready.connect(add_style_override_indicator_button.bind(l, object, name))

	return false


func _parse_begin(object: Object) -> void:
	## This lists all exposed properties of this object if it is a node and
	## part of a dialogic layout scene.

	style_exposed_props.clear()
	if not object is Node:
		return

	var base: Node = object.owner if object.owner else object

	if not base or not base.has_meta("style_customization"):
		return

	var path: String = "%"+object.name if object.unique_name_in_owner else str(base.get_path_to(object))

	var correct_node: bool = false
	for i in base.get_meta("style_customization") + base.get_meta("base_style_customization", []):
		if i.type == "Node":
			correct_node = i.name == path
			if i.name.ends_with("/@all_children"):
				if base.get_node(i.name.trim_suffix("/@all_children")) == object.get_parent():
					correct_node = true

		if correct_node and i.type == "Property":
			style_exposed_props.append(i.name)


func add_style_override_indicator_button(after_node:Control, object:Node, property:String) -> void:
	await after_node.get_tree().process_frame

	var b := Button.new()
	b.icon = after_node.get_theme_icon("Override", "EditorIcons")
	b.tooltip_text = "This property is exposed in the Dialogic style editor. \nYou can set it's default here, but it might be overwritten at runtime."
	b.theme_type_variation = "FlatButton"
	b.add_theme_color_override("icon_normal_color", after_node.get_theme_color("accent_color", "Editor"))
	b.pressed.connect(DialogicUtil.get_dialogic_plugin().layout_scene_sidebar.property_override_button_clicked.bind(object, property))


	var next_node := after_node.get_parent().get_child(after_node.get_index()+1)
	next_node.get_child(0).add_child(b)
	next_node.draw_warning = true

	after_node.queue_free()
