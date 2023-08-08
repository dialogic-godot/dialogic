@tool
extends DialogicCharacterEditorMainSection

## Character editor tab that allows editing typing sound moods.

var current_mood := ''
var current_moods_info := {}
var default_mood := ''

################################################################################
##					COMMUNICATION WITH EDITOR
################################################################################

func _load_character(character:DialogicCharacter):
	default_mood = character.custom_info.get('sound_mood_default', '')
	
	current_moods_info = character.custom_info.get('sound_moods', {}).duplicate(true)
	
	current_mood = ""
	update_mood_list()
	
	character_editor.get_settings_section_by_name('Typing Sound Mood', false).update_visibility(%MoodList.item_count != 0)


func _save_changes(character:DialogicCharacter) -> DialogicCharacter:
	# Quickly save latest mood
	if current_mood:
		current_moods_info[current_mood] = get_mood_info()
	
	character.custom_info['sound_mood_default'] = default_mood
	character.custom_info['sound_moods'] = current_moods_info.duplicate(true)
	return character


func get_portrait_data() -> Dictionary:
	if character_editor.selected_item and is_instance_valid(character_editor.selected_item):
		return character_editor.selected_item.get_metadata(0)
	return {}


func set_portrait_data(data:Dictionary) -> void:
	if character_editor.selected_item and is_instance_valid(character_editor.selected_item):
		character_editor.selected_item.set_metadata(0, data)


################################################################################
##					OWN STUFF
################################################################################

func _ready() -> void:
	%ListPanel.self_modulate = get_theme_color("base_color", "Editor")
	%Add.icon = get_theme_icon("Add", "EditorIcons")
	%Delete.icon = get_theme_icon("Remove", "EditorIcons")
	%Duplicate.icon = get_theme_icon("Duplicate", "EditorIcons")
	%Play.icon = get_theme_icon("Play", "EditorIcons")
	%Default.icon = get_theme_icon("NonFavorite", "EditorIcons")
	
	%NameWarning.texture = get_theme_icon("StatusWarning", "EditorIcons")


func update_mood_list(selected_name := "") -> void:
	%MoodList.clear()
	
	for mood in current_moods_info:
		var idx :int = %MoodList.add_item(mood, get_theme_icon("AudioStreamPlayer", "EditorIcons"))
		if mood == selected_name:
			%MoodList.select(idx)
			_on_mood_list_item_selected(idx)
	if !%MoodList.is_anything_selected() and %MoodList.item_count:
		%MoodList.select(0)
		_on_mood_list_item_selected(0)
	
	if %MoodList.item_count == 0:
		current_mood = ""
	
	%Delete.disabled = !%MoodList.is_anything_selected()
	%Play.disabled = !%MoodList.is_anything_selected()
	%Duplicate.disabled = !%MoodList.is_anything_selected()
	%Default.disabled = !%MoodList.is_anything_selected()
	%Settings.visible = %MoodList.is_anything_selected()
	
	%MoodList.custom_minimum_size.y = min(%MoodList.item_count*45, 100)
	%MoodList.visible = %MoodList.item_count != 0


func _input(event:InputEvent) -> void:
	if !is_visible_in_tree() or (get_viewport().gui_get_focus_owner() and !name+'/' in str(get_viewport().gui_get_focus_owner().get_path())):
		return
	if event is InputEventKey and event.keycode == KEY_F2 and event.pressed:
		if %MoodList.is_anything_selected():
			%Name.grab_focus()
			%Name.select_all()
			get_viewport().set_input_as_handled()


func _on_mood_list_item_selected(index:int) -> void:
	if current_mood:
		current_moods_info[current_mood] = get_mood_info()
	
	current_mood = %MoodList.get_item_text(index)
	load_mood_info(current_moods_info[current_mood])
	
	%Delete.disabled = !%MoodList.is_anything_selected()
	%Play.disabled = !%MoodList.is_anything_selected()
	%Duplicate.disabled = !%MoodList.is_anything_selected()
	%Default.disabled = !%MoodList.is_anything_selected()
	%Settings.visible = %MoodList.is_anything_selected()


func load_mood_info(dict:Dictionary) -> void:
	%Name.text = dict.get('name', '')
	%NameWarning.hide()
	set_default_button(default_mood == dict.get('name', ''))
	%SoundFolder.set_value(dict.get('sound_path', ''))
	%Mode.select(dict.get('mode', 0))
	%PitchBase.set_value(dict.get('pitch_base', 1))
	%PitchVariance.set_value(dict.get('pitch_variance', 0))
	%VolumeBase.set_value(dict.get('volume_base', 0))
	%VolumeVariance.set_value(dict.get('volume_variance', 0))
	%Skip.set_value(dict.get('skip_characters', 0))


func get_mood_info() -> Dictionary:
	var dict := {}
	dict['name'] = %Name.text
	dict['sound_path'] = %SoundFolder.current_value
	dict['mode'] = %Mode.selected
	dict['pitch_base'] = %PitchBase.value
	dict['pitch_variance'] = %PitchVariance.value
	dict['volume_base'] = %VolumeBase.value
	dict['volume_variance'] = %VolumeVariance.value
	dict['skip_characters'] = %Skip.value
	return dict


func _on_add_pressed() -> void:
	if !current_mood.is_empty():
		current_moods_info[current_mood] = get_mood_info()
	
	var new_name := 'Mood '
	var counter := 1
	while new_name+str(counter) in current_moods_info:
		counter+=1
	new_name += str(counter)
	
	current_moods_info[new_name] = {'name':new_name}
	update_mood_list(new_name)


func _on_duplicate_pressed() -> void:
	if !current_mood.is_empty():
		current_moods_info[current_mood] = get_mood_info()
	
	current_moods_info[current_mood+"_copy"] = get_mood_info()
	current_moods_info[current_mood+"_copy"].name = current_mood+"_copy"
	update_mood_list(current_mood+"_copy")


func _on_delete_pressed() -> void:
	if current_mood.is_empty():
		return
	current_moods_info.erase(current_mood)
	current_mood = ""
	update_mood_list()


func _on_name_text_changed(new_text:String) -> void:
	if new_text.is_empty():
		%NameWarning.show()
		%NameWarning.tooltip_text = "Name cannot be empty!"
	elif new_text in current_moods_info and new_text != current_mood:
		%NameWarning.show()
		%NameWarning.tooltip_text = "Name is already in use!"
	else:
		%NameWarning.hide()


func _on_name_text_submitted(new_text:String) -> void:
	if %NameWarning.visible:
		new_text = current_mood
		%NameWarning.hide()
	else:
		%MoodList.set_item_text(%MoodList.get_selected_items()[0], new_text)
		current_moods_info.erase(current_mood)
		current_moods_info[new_text] = get_mood_info()
		current_mood = new_text


func _on_name_focus_exited() -> void:
	_on_name_text_submitted(%Name.text)


func _on_default_toggled(button_pressed:bool) -> void:
	if button_pressed:
		default_mood = current_mood
	else:
		default_mood = ''
	set_default_button(button_pressed)


func set_default_button(enabled:bool) -> void:
	%Default.set_pressed_no_signal(enabled)
	if enabled:
		%Default.icon = get_theme_icon("Favorites", "EditorIcons")
	else:
		%Default.icon = get_theme_icon("NonFavorite", "EditorIcons")


func preview() -> void:
	$Preview.load_overwrite(get_mood_info())
	var preview_timer := Timer.new()
	DialogicUtil.update_timer_process_callback(preview_timer)
	add_child(preview_timer)
	preview_timer.start(ProjectSettings.get_setting('dialogic/settings/text_speed', 0.01))
	
	for i in range(20):
		$Preview._on_continued_revealing_text("a")
		await preview_timer.timeout
	
	preview_timer.queue_free()
