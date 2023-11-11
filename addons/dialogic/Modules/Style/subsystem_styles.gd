extends DialogicSubsystem

## Subsystem that manages loading layouts with specific styles applied.

signal style_changed(info:Dictionary)

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	pass


func load_game_state(load_flag:=LoadFlags.FULL_LOAD):
	if load_flag == LoadFlags.ONLY_DNODES:
		return
	add_layout_style(dialogic.current_state_info.get('style', ''))


####################################################################################################
##					MAIN METHODS
####################################################################################################

func add_layout_style(style_name:="", is_base_style:=true) -> Node:
	var styles_info := ProjectSettings.get_setting('dialogic/layout/styles', {'Default':{}})
	if style_name.is_empty() or !style_name in styles_info:
		style_name = ProjectSettings.get_setting('dialogic/layout/default_style', 'Default')
	var info := {'style':style_name}

	# is_base_style should only be wrong on temporary changes like character styles
	if is_base_style:
		dialogic.current_state_info['base_style'] = style_name

	var previous := Dialogic.get_layout_node()

	var layout_path := DialogicUtil.get_inherited_style_layout(style_name)
	var layout := Dialogic.add_layout_node(layout_path)


	# apply export overrides, in case this isn't the exact same style
	if !layout.has_meta('style') or !layout.get_meta('style', null) == style_name:
		DialogicUtil.apply_scene_export_overrides(layout, DialogicUtil.get_inherited_style_overrides(style_name))
		layout.set_meta('style', style_name)

	if layout != previous and previous != null:
		if previous.has_meta('style'): info['previous'] = previous.get_meta('style')
		previous.get_parent().remove_child(previous)
		layout.ready.connect(reload_current_info_into_new_style)

	dialogic.current_state_info['style'] = style_name

	style_changed.emit(info)
	return layout


func reload_current_info_into_new_style():
	for subsystem in Dialogic.get_children():
		subsystem.load_game_state(LoadFlags.ONLY_DNODES)


## Returns the style currently in use
func get_current_style() -> String:
	if Dialogic.has_active_layout_node():
		return Dialogic.get_layout_node().get_meta('style', '')
	return ''


#func enable_layer(layer_name:String) -> void:
#	var style_found: bool = false
#	var last_style := ""
#	dialogic.current_state_info['style'] = style_name
#	for style_node in get_tree().get_nodes_in_group('dialogic_styles'):
#		if style_node.style_name == style_name:
#			style_node.show()
#			style_found = true
#		else:
#			if style_node.visible:
#				last_style = style_node.style_name
#				style_node.hide()
#
#	if (!style_found):
#		for style_node in get_tree().get_nodes_in_group('dialogic_styles'):
#			if style_node.style_name == last_style:
#				style_node.show()
#		style_changed.emit({'style_name':style_name})
