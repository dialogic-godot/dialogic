tool
extends HBoxContainer

signal character_selected(value)


func _ready():
	$Dropdown.get_popup().connect("index_pressed", self, '_on_character_selected')


func _on_Dropdown_about_to_show():
	var popup = $Dropdown.get_popup()
	popup.clear()
	popup.add_item('No Character')
	popup.set_item_metadata(0, {'file': '', 'color': Color('#ffffff')})
	
	var index = 1
	for c in DialogicUtil.get_sorted_character_list():
		popup.add_item(c['name'])
		popup.set_item_metadata(index, {'file': c['file'],'color': c['color']})
		index += 1


func _on_character_selected(index: int):
	var data = {'file': '', 'color': Color('#FFFFFF')}
	if index == 0:
		set_data('[Character]', Color('#FFFFFF'))
	else:
		var metadata = $Dropdown.get_popup().get_item_metadata(index)
		set_data($Dropdown.get_popup().get_item_text(index), metadata['color'])
		data['file'] = metadata['file']
		data['color'] = metadata['color']
	
	emit_signal('character_selected', data)
	return data


func set_data_by_file(file_name):
	# This method is used when you don't know the character's color
	var character = DialogicResources.get_character_json(file_name)
	set_data(character['name'], Color(character['color']))


func set_data(text: String, color:Color = Color('#FFFFFF')) -> void:
	$Dropdown.text = text
	$Icon.set("self_modulate", Color(color))
