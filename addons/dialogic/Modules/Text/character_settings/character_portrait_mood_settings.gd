@tool
extends DialogicCharacterEditorPortraitSection


func _ready() -> void:
	%PortraitMood.get_suggestions_func = mood_suggestions


func _load_portrait_data(data:Dictionary):
	%PortraitMood.set_value(data.get('mood'))


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
	for child in character_editor.get_settings_section_by_name('Typing Sounds').get_node('%Moods').get_children():
		suggestions[child.get_data().name] = {'value':child.get_data().name}
	return suggestions
