tool
extends HSplitContainer


var editor_reference
var opened_character_data
var portrait_entry = load("res://addons/dialogic/Editor/CharacterEditor/PortraitEntry.tscn")
onready var character_editor = {
	'editor': $CharacterEditor/HBoxContainer/Container,
	'name': $CharacterEditor/HBoxContainer/Container/Name/LineEdit,
	'description': $CharacterEditor/HBoxContainer/Container/Description/TextEdit,
	'file': $CharacterEditor/HBoxContainer/Container/FileName/LineEdit,
	'color': $CharacterEditor/HBoxContainer/Container/Color/ColorPickerButton,
	'default_speaker': $CharacterEditor/HBoxContainer/Container/Actions/DefaultSpeaker,
	'display_name_checkbox': $CharacterEditor/HBoxContainer/Container/Name/CheckBox,
	'display_name': $CharacterEditor/HBoxContainer/Container/DisplayName/LineEdit,
}


func _ready():
	pass


func _on_CheckBox_toggled(button_pressed):
	$CharacterEditor/HBoxContainer/Container/DisplayName.visible = button_pressed


func refresh_character_list():
	var selected_id = 0
	if $CharacterTools/CharacterItemList.is_anything_selected():
		selected_id = $CharacterTools/CharacterItemList.get_selected_items()[0]

	$CharacterTools/CharacterItemList.clear()
	var icon = load("res://addons/dialogic/Images/character.svg")
	var index = 0
	for c in DialogicUtil.get_character_list():
		$CharacterTools/CharacterItemList.add_item(c['name'], icon)
		$CharacterTools/CharacterItemList.set_item_metadata(index, {'file': c['file'], 'index': index})
		$CharacterTools/CharacterItemList.set_item_icon_modulate(index, c['color'])
		index += 1

	# If there are no characters, show the welcome screen
	if index == 0:
		$NoCharacters.visible = true
		$CharacterEditor.visible = false
	else:
		$NoCharacters.visible = false
		$CharacterEditor.visible = true


func clear_character_editor():
	character_editor['file'].text = ''
	character_editor['name'].text = ''
	character_editor['description'].text = ''
	character_editor['color'].color = Color('#ffffff')
	character_editor['default_speaker'].pressed = false
	character_editor['display_name_checkbox'].pressed = false
	character_editor['display_name'].text = ''
	character_editor['portraits'] = []
	# Clearing portraits
	for p in $CharacterEditor/HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList.get_children():
		p.queue_free()
	$CharacterEditor/HBoxContainer/VBoxContainer/Control/TextureRect.texture = null


# Character Creation
func create_character():
	var character_file = 'character-' + str(OS.get_unix_time()) + '.json'
	var character = {
		'color': '#ffffff',
		'id': character_file,
		'default_speaker': false,
		'portraits': []
	}
	var directory = Directory.new()
	if not directory.dir_exists(DialogicUtil.get_path('WORKING_DIR')):
		directory.make_dir(DialogicUtil.get_path('WORKING_DIR'))
	if not directory.dir_exists(DialogicUtil.get_path('CHAR_DIR')):
		directory.make_dir(DialogicUtil.get_path('CHAR_DIR'))
	var file = File.new()
	file.open(DialogicUtil.get_path('CHAR_DIR', character_file), File.WRITE)
	file.store_line(to_json(character))
	file.close()
	return character_file


func _on_New_Character_Button_pressed():
	var file = create_character()
	refresh_character_list()
	for i in range($CharacterTools/CharacterItemList.get_item_count()):
		if $CharacterTools/CharacterItemList.get_item_metadata(i)['file'] == file:
			$CharacterTools/CharacterItemList.select(i)
			_on_ItemList_item_selected(i)


# Saving and Loading
func _on_SaveButton_pressed():
	save_current_character()


func generate_character_data_to_save():
	var default_speaker: bool = character_editor['default_speaker'].pressed
	var portraits = []
	for p in $CharacterEditor/HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList.get_children():
		var entry = {}
		entry['name'] = p.get_node("NameEdit").text
		entry['path'] = p.get_node("PathEdit").text
		portraits.append(entry)
	var info_to_save = {
		'id': character_editor['file'].text,
		'description': character_editor['description'].text,
		'color': '#' + character_editor['color'].color.to_html(),
		'default_speaker': default_speaker,
		'portraits': portraits,
		'display_name_bool': character_editor['display_name_checkbox'].pressed,
		'display_name': character_editor['display_name'].text,
	}
	# Adding name later for cases when no name is provided
	if character_editor['name'].text != '':
		info_to_save['name'] = character_editor['name'].text
	
	return info_to_save


func save_current_character():
	var path = DialogicUtil.get_path('CHAR_DIR', character_editor['file'].text)
	var info_to_save = generate_character_data_to_save()
	if info_to_save['id']:
		var file = File.new()
		file.open(path, File.WRITE)
		file.store_line(to_json(info_to_save))
		file.close()
		opened_character_data = info_to_save
		refresh_character_list()


func _on_ItemList_item_selected(index):
	var selected = $CharacterTools/CharacterItemList.get_item_text(index)
	var file = $CharacterTools/CharacterItemList.get_item_metadata(index)['file']
	var data = DialogicUtil.load_json(DialogicUtil.get_path('CHAR_DIR', file))
	$CharacterEditor/HBoxContainer/Container.visible = true
	load_character_editor(data)


func load_character_editor(data):
	clear_character_editor()
	opened_character_data = data
	character_editor['file'].text = data['id']
	character_editor['default_speaker'].pressed = false
	if data.has('name'):
		character_editor['name'].text = data['name']
	if data.has('description'):
		character_editor['description'].text = data['description']
	if data.has('color'):
		character_editor['color'].color = Color(data['color'])
	if data.has('default_speaker'):
		if data['default_speaker']:
			character_editor['default_speaker'].pressed = true
	
	if data.has('display_name_bool'):
		character_editor['display_name_checkbox'].pressed = data['display_name_bool']
	if data.has('display_name'):
		character_editor['display_name'].text = data['display_name']

	# Portraits
	var default_portrait = create_portrait_entry()
	default_portrait.get_node('NameEdit').text = 'Default'
	default_portrait.get_node('NameEdit').editable = false
	if data.has('portraits'):
		for p in data['portraits']:
			if p['name'] == 'Default':
				default_portrait.get_node('PathEdit').text = p['path']
				default_portrait.update_preview(p['path'])
			else:
				create_portrait_entry(p['name'], p['path'])


# Removing character
func _on_RemoveConfirmation_confirmed():
	var selected = $CharacterTools/CharacterItemList.get_selected_items()[0]
	var file = $CharacterTools/CharacterItemList.get_item_metadata(selected)['file']
	var dir = Directory.new()
	dir.remove(DialogicUtil.get_path('CHAR_DIR', file))
	$CharacterEditor/HBoxContainer/Container.visible = false
	clear_character_editor()
	refresh_character_list()


# Portraits
func _on_New_Portrait_Button_pressed():
	create_portrait_entry('', '', true)


func create_portrait_entry(p_name = '', path = '', grab_focus = false):
	var p = portrait_entry.instance()
	p.editor_reference = editor_reference
	p.image_node = $CharacterEditor/HBoxContainer/VBoxContainer/Control/TextureRect
	var p_list = $CharacterEditor/HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList
	p_list.add_child(p)
	if p_name != '':
		p.get_node("NameEdit").text = p_name
	if path != '':
		p.get_node("PathEdit").text = path
	if grab_focus:
		p.get_node("NameEdit").grab_focus()
		p._on_ButtonSelect_pressed()
	return p


func _on_CharacterItemList_item_rmb_selected(index, at_position):
	editor_reference.get_node("CharacterPopupMenu").rect_position = get_viewport().get_mouse_position()
	editor_reference.get_node("CharacterPopupMenu").popup()


func _on_CharacterPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('CHAR_DIR')))
	if id == 1:
		editor_reference.get_node("RemoveCharacterConfirmation").popup_centered()
