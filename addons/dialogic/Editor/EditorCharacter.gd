tool
extends HSplitContainer


var editor_reference
var opened_character_data
onready var character_editor = {
	'editor': $CharacterEditor/HBoxContainer/Container,
	'name': $CharacterEditor/HBoxContainer/Container/Name/LineEdit,
	'description': $CharacterEditor/HBoxContainer/Container/Description/TextEdit,
	'file': $CharacterEditor/HBoxContainer/Container/FileName/LineEdit,
	'color': $CharacterEditor/HBoxContainer/Container/Color/ColorPickerButton,
	'default_speaker': $CharacterEditor/HBoxContainer/Container/Actions/DefaultSpeaker,
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
	for c in editor_reference.get_character_list():
		$CharacterTools/CharacterItemList.add_item(c['name'], icon)
		$CharacterTools/CharacterItemList.set_item_metadata(index, {'file': c['file'], 'index': index})
		$CharacterTools/CharacterItemList.set_item_icon_modulate(index, c['color'])
		index += 1
	if index >= selected_id:
		$CharacterTools/CharacterItemList.select(selected_id)
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


# Character Creation
func create_character():
	var character_file = 'character-' + str(OS.get_unix_time()) + '.json'
	var character = {
		'color': 'ffffff',
		'id': character_file,
		'default_speaker': 'false',
	}
	var directory = Directory.new()
	if not directory.dir_exists(editor_reference.WORKING_DIR):
		directory.make_dir(editor_reference.WORKING_DIR)
	if not directory.dir_exists(editor_reference.CHAR_DIR):
		directory.make_dir(editor_reference.CHAR_DIR)
	var file = File.new()
	file.open(editor_reference.CHAR_DIR + '/' + character_file, File.WRITE)
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
	var default_speaker = 'false'
	if character_editor['default_speaker'].pressed:
		default_speaker = 'true'
	var info_to_save = {
		'id': character_editor['file'].text,
		'description': character_editor['description'].text,
		'color': character_editor['color'].color.to_html(),
		'default_speaker': default_speaker,
	}
	# Adding name later for cases when no name is provided
	if character_editor['name'].text != '':
		info_to_save['name'] = character_editor['name'].text
	
	return info_to_save

func save_current_character():
	var path = editor_reference.CHAR_DIR + '/' + character_editor['file'].text
	var info_to_save = generate_character_data_to_save()
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()
	opened_character_data = info_to_save
	refresh_character_list()


func _on_ItemList_item_selected(index):
	var selected = $CharacterTools/CharacterItemList.get_item_text(index)
	var file = $CharacterTools/CharacterItemList.get_item_metadata(index)['file']
	var data = editor_reference.load_json(editor_reference.CHAR_DIR + '/' + file)
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
		character_editor['color'].color = Color('#' + data['color'])
	if data.has('default_speaker'):
		if data['default_speaker'] == 'true':
			character_editor['default_speaker'].pressed = true


# Removing character
func _on_RemoveConfirmation_confirmed():
	var selected = $CharacterTools/CharacterItemList.get_selected_items()[0]
	var file = $CharacterTools/CharacterItemList.get_item_metadata(selected)['file']
	print('Remove ', $CharacterTools/CharacterItemList.get_item_metadata(selected)['file'])
	var dir = Directory.new()
	dir.remove(editor_reference.CHAR_DIR + '/' + file)
	$CharacterEditor/HBoxContainer/Container.visible = false
	clear_character_editor()
	refresh_character_list()


func _on_DeleteButton_pressed():
	editor_reference.get_node("RemoveConfirmation").popup_centered()
