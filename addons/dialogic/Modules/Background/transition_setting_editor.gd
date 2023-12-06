@tool
extends HSplitContainer

var current_transition: DialogicTransition = null

var customization_editor_info := {}

func load_transition(transition: DialogicTransition) -> void:
	current_transition = transition
	
	load_transition_settings_list()

func load_transition_settings_list() -> void:
	var overrides := current_transition.get_transition_overrides()
	var inherrited_overrides := current_transition.get_transition_overrides(true)
	
	%SmallTransitionPreview.hide()
	
	load_transition_customization(overrides, inherrited_overrides)

func load_transition_customization(overrides: Dictionary = {}, inherited_overrides: Dictionary = {}) -> void:
	for child in %TransitionSettingsTabs.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	
	var shader = current_transition.get_shader()
	
	var settings := []
	
	settings.append({'name':'Resource', 'added':false, 'id':&"GROUP"})
	
	var transition_properties = current_transition.get_property_list()
	var prop = transition_properties.filter(func (p: Variant) -> bool: return p['name'] == "shader")[0]
	prop['id'] = &"SETTING"
	settings.append(prop)
	
	if shader:
		settings.append_array(collect_settings(shader.get_shader_uniform_list()))
	
	if settings.is_empty():
		var note := Label.new()
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.text = "This layer has no exposed settings."
		note.theme_type_variation = 'DialogicHintText2'
		%TransitionSettingsTabs.add_child(note)
		note.name = "General"
		return
	
	var current_grid: GridContainer = null
	
	var label_bg_style = get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles").duplicate()
	label_bg_style.content_margin_left = 5
	label_bg_style.content_margin_right = 5
	label_bg_style.content_margin_top = 5
	
	var current_group_name := ""
	var current_subgroup_name := ""
	customization_editor_info = {}
	
	for i in settings:
		match i['id']:
			&"GROUP":
				var main_scroll = ScrollContainer.new()
				main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
				main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.name = i['name']
				%TransitionSettingsTabs.add_child(main_scroll, true)

				current_grid = GridContainer.new()
				current_grid.columns = 3
				current_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.add_child(current_grid)
				current_group_name = i['name'].to_snake_case()
				current_subgroup_name = ""
	
			&"SUBGROUP":
	
				# add separator
				if current_subgroup_name:
					current_grid.add_child(HSeparator.new())
					current_grid.get_child(-1).add_theme_constant_override('separation', 20)
					current_grid.add_child(current_grid.get_child(-1).duplicate())
					current_grid.add_child(current_grid.get_child(-1).duplicate())
	
				var title_label := Label.new()
				title_label.text = i['name']
				title_label.theme_type_variation = "DialogicSection"
				title_label.size_flags_horizontal = SIZE_EXPAND_FILL
				current_grid.add_child(title_label, true)
	
				# add spaced to the grid
				current_grid.add_child(Control.new())
				current_grid.add_child(Control.new())
	
				current_subgroup_name = i['name'].to_snake_case()
	
			&"SETTING":
				var label := Label.new()
				label.text = str(i['name'].trim_prefix(current_group_name+'_').trim_prefix(current_subgroup_name+'_')).capitalize()
				current_grid.add_child(label, true)
				
				customization_editor_info[i['name']] = {}
				var current_value :Variant
				var input :Node 
				
				if current_group_name == "resource":
					current_value = current_transition.shader
					customization_editor_info[i['name']]['orig'] = preload("res://addons/dialogic/Modules/Background/default_background_transition.gdshader")
				
				else:
					if i['name'] in inherited_overrides:
						var override = inherited_overrides.get(i['name'])
						customization_editor_info[i['name']]['orig'] = str_to_var(override) if override is String else override
					else:
						customization_editor_info[i['name']]['orig'] = RenderingServer.shader_get_parameter_default(shader.get_rid(), i['name'])
					
					if i['name'] in overrides:
						var override = overrides.get(i['name'])
						current_value = str_to_var(override) if override is String else override
					else:
						current_value = customization_editor_info[i['name']]['orig']
					
					input= DialogicUtil.setup_script_property_edit_node(i, current_value, set_export_override)
				
				# TODO: remove manual overriding once resources are supported in dialogic utils
				if i['type'] == TYPE_OBJECT:
					input = EditorResourcePicker.new()
					input.edited_resource = current_value
					input.base_type = i['hint_string']
					
					if current_group_name == "resource":
						if current_transition.inherits_anything() and 'editable' in input:
							input.editable = false
						
						#TODO: make this less specific so it can be used for more than one parameter
						input.resource_changed.connect(func (resource: Resource) -> void: 
							current_transition.shader = resource as Shader
							)
					
					else:
						input.resource_changed.connect(func (resource: Resource) -> void:
							if resource != customization_editor_info[i.name]['orig']:
								current_transition.set_parameter(i.name, resource)
								customization_editor_info[i.name]['reset'].disabled = false
							else:
								current_transition.remove_paramter(i.name)
								customization_editor_info[i.name]['reset'].disabled = true
							)
				
				
				
				input.size_flags_horizontal = SIZE_EXPAND_FILL
				customization_editor_info[i['name']]['node'] = input
				
				var reset := Button.new()
				reset.flat = true
				reset.icon = get_theme_icon("Reload", "EditorIcons")
				reset.tooltip_text = "Remove customization"
				customization_editor_info[i['name']]['reset'] = reset
				reset.disabled = current_value == customization_editor_info[i['name']]['orig']
				current_grid.add_child(reset)
				if current_group_name == "resource":
					reset.pressed.connect(func() :
						var default_shader = customization_editor_info[i['name']]['orig']
						current_transition.shader = default_shader
						customization_editor_info[i['name']]['reset'].disabled = true
						set_customization_value(i['name'], default_shader)
					)
				else:
					reset.pressed.connect(_on_export_override_reset.bind(i['name']))
				current_grid.add_child(input)


func collect_settings(properties: Array) -> Array[Dictionary]:
	var settings: Array[Dictionary] = []

	var current_group := {}
	var current_subgroup := {}

	for i in properties:
		if i['usage'] & PROPERTY_USAGE_CATEGORY:
			continue

		if (i['usage'] & PROPERTY_USAGE_GROUP):
			current_group = i
			current_group['added'] = false
			current_group['id'] = &'GROUP'
			current_subgroup = {}

		elif i['usage'] & PROPERTY_USAGE_SUBGROUP:
			current_subgroup = i
			current_subgroup['added'] = false
			current_subgroup['id'] = &'SUBGROUP'

		elif i['usage'] & PROPERTY_USAGE_EDITOR:
			if _is_reserved_uniform(i):
				continue
			
			if current_group.get('name', '') == 'Private':
				continue

			if current_group.is_empty():
				current_group = {'name':'Parameters', 'added':false, 'id':&"GROUP"}

			if current_group.get('added', true) == false:
				settings.append(current_group)
				current_group['added'] = true

			if current_subgroup.is_empty():
				current_subgroup = {'name':current_group['name'], 'added':false, 'id':&"SUBGROUP"}

			if current_subgroup.get('added', true) == false:
				settings.append(current_subgroup)
				current_subgroup['added'] = true

			i['id'] = &'SETTING'
			settings.append(i)
	return settings


func set_export_override(property_name: String, value: String = "") -> void:
	if str_to_var(value) != customization_editor_info[property_name]['orig']:
		current_transition.set_parameter(property_name, value)
		customization_editor_info[property_name]['reset'].disabled = false
	else:
		current_transition.remove_paramter(property_name)
		customization_editor_info[property_name]['reset'].disabled = true


func _on_export_override_reset(property_name: String) -> void:
	current_transition.remove_paramter(property_name)
	customization_editor_info[property_name]['reset'].disabled = true
	set_customization_value(property_name, customization_editor_info[property_name]['orig'])


func set_customization_value(property_name:String, value:Variant) -> void:
	var node : Node = customization_editor_info[property_name]['node']
	
	if node is CheckBox:
		node.button_pressed = true if value else false
	elif node is LineEdit:
		node.text = value
	elif node is EditorResourcePicker:
		node.edited_resource = value
	elif node.has_method('set_value'):
		node.set_value(0 if !value else value)
	elif node is ColorPickerButton:
		node.color = value
	elif node is OptionButton:
		node.select(value)
	elif node is SpinBox:
		node.value = 0 if !value else value

func _is_reserved_uniform(uniform: Variant) -> bool:
	return uniform["name"] == "progress" || uniform["name"] == "previous_background" || uniform["name"] == "next_background"


func _on_expand_transition_info_pressed() -> void:
	if %TransitionInfoBody.visible:
		%TransitionInfoBody.hide()
		%ExpandTransitionInfo.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	else:
		%TransitionInfoBody.show()
		%ExpandTransitionInfo.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")
