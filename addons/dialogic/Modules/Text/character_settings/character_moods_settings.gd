@tool
extends DialogicCharacterEditorMainSection

## Character editor tab that allows editing typing sound moods.


################################################################################
##					COMMUNICATION WITH EDITOR
################################################################################

func _load_character(character:DialogicCharacter):
	for mood in %Moods.get_children():
		mood.queue_free()
	
	%DefaultMood.set_value(character.custom_info.get('sound_moods_default', ''))
	
	for mood in character.custom_info.get('sound_moods', {}):
		create_mood_item(character.custom_info.sound_moods[mood])
	
	character_editor.get_settings_section_by_name('Typing Sound Mood', false).update_visibility(%Moods.get_child_count() != 0)


func _save_changes(character:DialogicCharacter) -> DialogicCharacter:
	var moods := {}
	for node in %Moods.get_children():
		moods[node.get_data().name] = node.get_data()
	character.custom_info['sound_mood_default'] = %DefaultMood.current_value
	character.custom_info['sound_moods'] = moods
	return character


func get_portrait_data() -> Dictionary:
	if character_editor.selected_item and is_instance_valid(character_editor.selected_item):
		return character_editor.selected_item.get_metadata(0)
	return {}


func set_portrait_data(data:Dictionary) -> void:
	if character_editor.selected_item and is_instance_valid(character_editor.selected_item):
		character_editor.selected_item.set_metadata(0, data)


func _ready():
	%DefaultMood.get_suggestions_func = mood_suggestions
	%AddMood.icon = get_theme_icon("Add", "EditorIcons")



################################################################################
##					OWN STUFF
################################################################################

func _on_AddMood_pressed() -> void:
	create_mood_item({})
	changed.emit()


func create_mood_item(data:Dictionary) -> void:
	var new_mood :Control = load(get_script().resource_path.get_base_dir().path_join('ui_mood_item.tscn')).instantiate()
	%Moods.add_child(new_mood)
	new_mood.load_data(data)
	new_mood.duplicate_request.connect(duplicate_mood_item.bind(new_mood))
	new_mood.changed.connect(emit_signal.bind('changed'))
	
	character_editor.get_settings_section_by_name('Typing Sound Mood', false).update_visibility(true)


func duplicate_mood_item(item:Control) -> void:
	changed.emit()
	create_mood_item(item.get_data())


func mood_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	for child in %Moods.get_children():
		suggestions[child.get_data().name] = {'value':child.get_data().name}
	return suggestions


func _on_default_mood_value_changed(property_name:String, value:Variant):
	var data: Dictionary = get_portrait_data()
	data['sound_mood_default'] = value
	set_portrait_data(data)
	changed.emit()


func _on_moods_child_exiting_tree(node):
	character_editor.get_settings_section_by_name('Typing Sound Mood', false).update_visibility(%Moods.get_child_count()-1 != 0)
