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
	load_style(dialogic.current_state_info.get('style', ''))


####################################################################################################
##					MAIN METHODS
####################################################################################################

func load_style(style_name:="", is_base_style:=true) -> Node:
	var styles_info := ProjectSettings.get_setting('dialogic/layout/styles', {'Default':{}})

	if style_name.is_empty() or !style_name in styles_info:
		style_name = ProjectSettings.get_setting('dialogic/layout/default_style', 'Default')
	var signal_info := {'style':style_name}

	# is_base_style should only be wrong on temporary changes like character styles
	if is_base_style:
		dialogic.current_state_info['base_style'] = style_name

	# if this style is the same style as before
	var previous_layout := get_layout_node()
	if (is_instance_valid(previous_layout)
			and previous_layout.has_meta('style')
			and previous_layout.get_meta('style') == style_name):

		pass # DO THIS IF IT'S THE EXACT SAME STYLE
		return previous_layout

	# if this is another style:
	var new_layout := create_layout(styles_info[style_name])

	if new_layout != previous_layout and previous_layout != null:
		if previous_layout.has_meta('style'): signal_info['previous'] = previous_layout.get_meta('style')
		previous_layout.queue_free()
		new_layout.ready.connect(reload_current_info_into_new_style)

	dialogic.current_state_info['style'] = style_name

	style_changed.emit(signal_info)
	return new_layout



## Method that adds a layout scene with all the necessary layers.
## The layout scene will be added to the tree root and returned.
func create_layout(style_info:Dictionary) -> DialogicLayoutBase:

	# Load base scene
	var base_scene : DialogicLayoutBase
	if not ResourceLoader.exists(style_info.get('base_scene_path', '')):
		base_scene = load(DialogicUtil.get_default_layout_base()).instantiate()
	else:
		base_scene = load(style_info.base_scene_path).instantiate()

	base_scene.name = "DialogicLayout_"+style_info.get('name', "Unnamed").to_pascal_case()

	# Apply base scene overrides
	DialogicUtil.apply_scene_export_overrides(base_scene, style_info.get('base_scene_overrides', {}))

	# Load layers
	for layer in style_info.get('layers', []):

		if not ResourceLoader.exists(layer.get('scene_path', '')):
			continue

		var layer_scene : DialogicLayoutLayer = load(layer.get('scene_path', '')).instantiate()

		base_scene.add_layer(layer_scene)

		# Apply layer overrides
		DialogicUtil.apply_scene_export_overrides(layer_scene, layer.get('scene_overrides', {}))

	base_scene.set_meta('style', style_info.get('name', 'UNNAMED STYLE'))

	Dialogic.get_parent().call_deferred("add_child", base_scene)
	Dialogic.get_tree().set_meta('dialogic_layout_node', base_scene)

	return base_scene


## When changing to a different layout scene,
## we have to load all the info from the current_state_info (basically
func reload_current_info_into_new_style():
	for subsystem in Dialogic.get_children():
		subsystem.load_game_state(LoadFlags.ONLY_DNODES)


## Returns the style currently in use
func get_current_style() -> String:
	if Dialogic.has_active_layout_node():
		return Dialogic.get_layout_node().get_meta('style', '')
	return ''


func has_active_layout_node() -> bool:
	return (
		get_tree().has_meta('dialogic_layout_node')
		and is_instance_valid(get_tree().get_meta('dialogic_layout_node'))
		and get_tree().get_meta('dialogic_layout_node').visible
	)


func get_layout_node() -> Node:
	var tree := get_tree()
	if tree.has_meta('dialogic_layout_node') and is_instance_valid(tree.get_meta('dialogic_layout_node')):
		return tree.get_meta('dialogic_layout_node')

	return null
