@tool
extends DialogicCharacterEditorPortraitSection

## Section that allows setting values of exported scene variables
## for custom portrait scenes

var current_portrait_data := {}
var last_scene := ""

func _get_title() -> String:
	return "Settings"


func _load_portrait_data(data:Dictionary) -> void:
	_recheck(data, true)


## Recheck section visibility and reload export fields.
## This allows reacting to changes of the portrait_scene setting.
func _recheck(data: Dictionary, force:=false):
	if last_scene == data.get("scene", "") and not force:
		current_portrait_data = data
		last_scene = data.get("scene", "")
		return

	last_scene = data.get("scene", "")
	current_portrait_data = data

	for child in $Grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()

	var scene: Variant = null

	if current_portrait_data.get('scene', '').is_empty():
		if ProjectSettings.get_setting('dialogic/portraits/default_portrait', '').is_empty():
			scene = load(character_editor.def_portrait_path)
		else:
			scene = load(ProjectSettings.get_setting('dialogic/portraits/default_portrait', ''))
	else:
		scene = load(current_portrait_data.get('scene'))

	if not scene:
		return

	scene = scene.instantiate()

	var skip := false
	for i in scene.script.get_script_property_list():
		if i['usage'] & PROPERTY_USAGE_EDITOR and !skip:
			var label := Label.new()
			label.text = i['name'].capitalize()
			$Grid.add_child(label)

			var current_value: Variant = scene.get(i['name'])
			if current_portrait_data.has('export_overrides') and current_portrait_data['export_overrides'].has(i['name']):
				current_value = str_to_var(current_portrait_data.export_overrides[i['name']])
				if current_value == null and typeof(scene.get(i['name'])) == TYPE_STRING:
					current_value = current_portrait_data['export_overrides'][i['name']]

			var input: Node = DialogicUtil.setup_script_property_edit_node(i, current_value, set_export_override)
			input.size_flags_horizontal = SIZE_EXPAND_FILL
			$Grid.add_child(input)

		if i['usage'] & PROPERTY_USAGE_GROUP:
			if i['name'] == 'Main' or i["name"] == "Private":
				skip = true
				continue
			else:
				skip = false

	if $Grid.get_child_count():
		get_parent().get_child(get_index()-1).show()
		show()
	else:
		hide()
		get_parent().get_child(get_index()-1).hide()
		get_parent().get_child(get_index()+1).hide()


## On any change, save the export override to the portrait items metadata.
func set_export_override(property_name:String, value:String = "") -> void:
	var data: Dictionary = selected_item.get_metadata(0)
	if !data.has('export_overrides'):
		data['export_overrides'] = {}
	if !value.is_empty():
		data.export_overrides[property_name] = value
	else:
		data.export_overrides.erase(property_name)
	changed.emit()
	update_preview.emit()
