@tool
extends DialogicCharacterEditorPortraitSettingsTab

## Tab that allows setting values of exported scene variables
## for custom portrait scenes

var current_portrait_data := {}

func _ready() -> void:
	get_parent().set_tab_icon(get_index(), get_theme_icon("EditInternal", "EditorIcons"))
	add_theme_stylebox_override('panel', get_theme_stylebox("Background", "EditorStyles"))

func _load_portrait_data(data:Dictionary) -> void:
	if data.get('scene', '').is_empty():
		get_parent().set_tab_hidden(get_index(), true)
	else:
		get_parent().set_tab_hidden(get_index(), false)
	
		current_portrait_data = data
		load_portrait_scene_export_variables()

func load_portrait_scene_export_variables():
	var scene = null
	if !current_portrait_data.get('scene', '').is_empty():
		scene = load(current_portrait_data.get('scene'))
	
	if !scene:
		return
	
	for child in $Grid.get_children(): 
		child.queue_free()
	
	scene = scene.instantiate()
	for i in scene.script.get_script_property_list():
		if i['usage'] & PROPERTY_USAGE_EDITOR:
			var label = Label.new()
			label.text = i['name']
			label.add_theme_stylebox_override('normal', get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles"))
			$Grid.add_child(label)
			
			var current_value :Variant = scene.get(i['name'])
			if current_portrait_data.has('export_overrides') and current_portrait_data['export_overrides'].has(i['name']):
				current_value = str_to_var(current_portrait_data['export_overrides'][i['name']])
			
			var input :Node = DialogicUtil.setup_script_property_edit_node(
				i, current_value, 
				{'bool':_on_export_bool_submitted, 'color':_on_export_color_submitted, 'enum':_on_export_int_enum_submitted,
				'int':_on_export_number_submitted, 'float':_on_export_number_submitted, 'file':_on_export_file_submitted,
				'string':_on_export_input_text_submitted, "string_enum": _on_export_string_enum_submitted})
			
			input.size_flags_horizontal = SIZE_EXPAND_FILL
			$Grid.add_child(input)
		if i['usage'] & PROPERTY_USAGE_GROUP:
			var title := Label.new()
			title.text = i['name']
			title.add_theme_stylebox_override('normal', get_theme_stylebox("ContextualToolbar", "EditorStyles"))
			$Grid.add_child(title)
			$Grid.add_child(Control.new())

func set_export_override(property_name:String, value:String = "") -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	if !data.has('export_overrides'):
		data['export_overrides'] = {}
	
	if !value.is_empty():
		data['export_overrides'][property_name] = value
	else:
		data['export_overrides'].erase(property_name)
	
	changed.emit()
	update_preview.emit()

func _on_export_input_text_submitted(text:String, property_name:String) -> void:
	set_export_override(property_name, var_to_str(text))

func _on_export_bool_submitted(value:bool, property_name:String) -> void:
	set_export_override(property_name, var_to_str(value))

func _on_export_color_submitted(color:Color, property_name:String) -> void:
	set_export_override(property_name, var_to_str(color))

func _on_export_int_enum_submitted(item:int, property_name:String) -> void:
	set_export_override(property_name, var_to_str(item))

func _on_export_number_submitted(value:float, property_name:String) -> void:
	set_export_override(property_name, var_to_str(value))

func _on_export_file_submitted(property_name:String, value:String) -> void:
	set_export_override(property_name, value)

func _on_export_string_enum_submitted(value:int, property_name:String, list:PackedStringArray):
	set_export_override(property_name, list[value])
