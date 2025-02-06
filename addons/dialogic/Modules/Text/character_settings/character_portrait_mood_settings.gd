@tool
extends DialogicCharacterEditorPortraitSection


func _get_title() -> String:
	return "Typing Sound Mood"


func _ready() -> void:
	%PortraitMood.suggestions_func = mood_suggestions
	%PortraitMood.resource_icon = get_theme_icon("AudioStreamPlayer", "EditorIcons")


func _load_portrait_data(data:Dictionary):
	%PortraitMood.set_value(data.get('sound_mood'))


func update_visibility(show:=true):
	if !show:
		hide()
		get_parent().get_child(get_index()-1).hide()
		get_parent().get_child(get_index()+1).hide()
	else:
		get_parent().get_child(get_index()-1).show()


func _on_portrait_mood_value_changed(property_name:String, value:String):
	var data: Dictionary = selected_item.get_metadata(0)
	data['sound_mood'] = value
	changed.emit()


func mood_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	for mood in character_editor.get_settings_section_by_name('Typing Sounds').current_moods_info:
		suggestions[mood] = {'value':mood}
	return suggestions
