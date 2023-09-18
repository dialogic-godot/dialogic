@tool
extends DialogicCharacterEditorPortraitSection

## Tab that allows setting values of exported scene variables
## for custom portrait scenes

func _show_title() -> bool:
	return false

var current_portrait_data := {}

func _load_portrait_data(data:Dictionary) -> void:
	current_portrait_data = data
	load_portrait_scene_export_variables()


func load_portrait_scene_export_variables():
	for child in $Grid.get_children(): 
		child.queue_free()
	
	var scene = null
	if !current_portrait_data.get('scene', '').is_empty():
		scene = load(current_portrait_data.get('scene'))
	else:
		scene = load(ProjectSettings.get_setting('dialogic/portraits/default_portrait', ''))
	
	if !scene:
		return
	
	scene = scene.instantiate()
	var skip := true
	for i in scene.script.get_script_property_list():
		if i['usage'] & PROPERTY_USAGE_EDITOR and !skip:
			var label = Label.new()
			label.text = i['name']
			label.add_theme_stylebox_override('normal', get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles"))
			$Grid.add_child(label)
			
			var current_value :Variant = scene.get(i['name'])
			if current_portrait_data.has('export_overrides') and current_portrait_data['export_overrides'].has(i['name']):
				current_value = str_to_var(current_portrait_data['export_overrides'][i['name']])
			
			var input :Node = DialogicUtil.setup_script_property_edit_node(i, current_value, set_export_override)
			
			input.size_flags_horizontal = SIZE_EXPAND_FILL
			$Grid.add_child(input)
		if i['usage'] & PROPERTY_USAGE_GROUP:
			if i['name'] == 'Main':
				skip = false
			else:
				skip = true
				continue
			var title := Label.new()
			title.text = i['name']
			title.add_theme_stylebox_override('normal', get_theme_stylebox("ContextualToolbar", "EditorStyles"))
			$Grid.add_child(title)
			$Grid.add_child(Control.new())
	
	$Label.visible = $Grid.get_child_count() == 0


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
