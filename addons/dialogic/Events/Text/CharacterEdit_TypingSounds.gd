@tool
extends VBoxContainer

signal changed

func _ready():
	find_parent('CharacterEditor').portrait_selected.connect(_on_portrait_selected)
	%PortraitMood.get_suggestions_func = [self, 'mood_suggestions']
	%DefaultMood.get_suggestions_func = [self, 'mood_suggestions']

func load_character(character:DialogicCharacter):
	for mood in %Moods.get_children():
		mood.queue_free()
	
	%PortraitMood.set_value('')
	%DefaultMood.set_value(character.custom_info.get('sound_moods_default', ''))
	
	for mood in character.custom_info.get('sound_moods', {}):
		create_mood_item(character.custom_info.sound_moods[mood])

func save_character(character:DialogicCharacter):
	var moods = {}
	for node in %Moods.get_children():
		moods[node.get_data().name] = node.get_data()
	character.custom_info['sound_mood_default'] = %DefaultMood.current_value
	character.custom_info['sound_moods'] = moods

func _on_AddMood_pressed():
	create_mood_item({})
	emit_signal("changed")
	
func create_mood_item(data):
	var new_mood = load(get_script().resource_path.get_base_dir().plus_file('CharacterEdit_TypingSounds_MoodItem.tscn')).instantiate()
	%Moods.add_child(new_mood)
	new_mood.load_data(data)
	new_mood.duplicate.connect(duplicate_mood_item.bind(new_mood))
	new_mood.changed.connect(emit_signal.bind('changed'))

func duplicate_mood_item(item):
	emit_signal("changed")
	create_mood_item(item.get_data())

func _on_portrait_selected(previous, current):
	if current and is_instance_valid(current):
		%PortraitMood.set_value(current.portrait_data.get('sound_mood', ''))
		%PortraitMoodLabel.text = 'Mood for "%s":'%current.get_portrait_name()


func mood_suggestions(filter):
	var suggestions = {}
	for child in %Moods.get_children():
		if filter.is_empty() or filter.to_lower() in child.get_data().name.to_lower():
			suggestions[child.get_data().name] = {'value':child.get_data().name}
	return suggestions


func _on_PortraitMood_value_changed(property_name, value):
	if find_parent('CharacterEditor').current_portrait:
		find_parent('CharacterEditor').current_portrait.portrait_data['sound_mood'] = value
	emit_signal("changed")


func _on_default_mood_value_changed(property_name, value):
	if find_parent('CharacterEditor').current_portrait:
		find_parent('CharacterEditor').current_portrait.portrait_data['sound_mood_default'] = value
	emit_signal("changed")
