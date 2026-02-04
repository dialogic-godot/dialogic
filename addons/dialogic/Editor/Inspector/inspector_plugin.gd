@tool
extends EditorInspectorPlugin


func _can_handle(_object: Object) -> bool:
	return true


func _parse_property(_object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if type == TYPE_OBJECT and hint_type == PROPERTY_HINT_RESOURCE_TYPE:
		if hint_string == "DialogicTimeline":
			var editor: EditorProperty = load("res://addons/dialogic/Editor/Inspector/timeline_inspector_field.gd").new()
			add_property_editor(name, editor)
			return true

	if not _object is Node:
		return false

	var base : Node = _object.owner
	if not base:
		base = _object

	if base and base.has_meta("style_customization"):
		var path := ""
		if _object.unique_name_in_owner:
			path += "%"+_object.name
		else:
			path += str(base.get_path_to(_object))


		var found_node: Node = null
		for i in base.get_meta("style_customization"):
			if i.type == "Node":
				if found_node:
					break
				if i.name == path:
					found_node = _object

			if found_node and i.type == "Property" and i.name == name:
				var l := Control.new()
				add_custom_control(l)
				l.ready.connect(func():
					await l.get_tree().process_frame;
					var next_node := l.get_parent().get_child(l.get_index()+1)
					next_node.add_theme_color_override("Editor::warning_color", Color.HOT_PINK)
					var b := Button.new()
					b.icon = next_node.get_theme_icon("Override", "EditorIcons")
					b.add_theme_color_override("icon_normal_color", l.get_theme_color("accent_color", "Editor"))
					b.tooltip_text = "This property is exposed in the Dialogic style editor. \nYou can set it's default here, but it might be overwritten at runtime."
					b.theme_type_variation = "FlatButton"
					next_node.get_child(0).add_child(b)
					#next_node.modulate = Color.ORANGE
					next_node.draw_warning = true
					b.pressed.connect(DialogicUtil.get_dialogic_plugin().layout_scene_sidebar.property_override_button_clicked.bind(found_node, i.name))
					#print(next_node)
					l.queue_free()
					)
				#l.text = "ATTENTION EVERYONE. Catch spiderman."
				break

	return false


#func _parse_begin(object: Object) -> void:
	#if object is DialogicNode_DialogText:
		#var l := Label.new()
		#add_custom_control(l)
		#l.text = "THIS IS A PRIVATE NODE!!! DON'T LOOK!"
