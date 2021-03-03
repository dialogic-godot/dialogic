tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTree')
var opened_character_data
var portrait_entry = load("res://addons/dialogic/Editor/CharacterEditor/PortraitEntry.tscn")
onready var character_editor = {
	'editor': $HBoxContainer/Container,
	'name': $HBoxContainer/Container/Name/LineEdit,
	'description': $HBoxContainer/Container/Description/TextEdit,
	'file': $HBoxContainer/Container/FileName/LineEdit,
	'color': $HBoxContainer/Container/Color/ColorPickerButton,
	'default_speaker': $HBoxContainer/Container/Actions/DefaultSpeaker,
	'display_name_checkbox': $HBoxContainer/Container/Name/CheckBox,
	'display_name': $HBoxContainer/Container/DisplayName/LineEdit,
	'new_portrait_button': $HBoxContainer/Container/ScrollContainer/VBoxContainer/HBoxContainer/Button,
}


func _ready():
	character_editor['new_portrait_button'].connect('pressed', self, '_on_New_Portrait_Button_pressed')
	character_editor['display_name_checkbox'].connect('toggled', self, '_on_display_name_toggled')
	character_editor['name'].connect('text_changed', self, '_on_name_changed')
	character_editor['color'].connect('color_changed', self, '_on_color_changed')

func _on_display_name_toggled(button_pressed):
	$HBoxContainer/Container/DisplayName.visible = button_pressed


func _on_name_changed(value):
	var item = master_tree.get_selected()
	item.set_text(0, value)

func _on_color_changed(color):
	var item = master_tree.get_selected()
	item.set_icon_modulate(0, color)


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
	for p in $HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList.get_children():
		p.queue_free()
	$HBoxContainer/VBoxContainer/Control/TextureRect.texture = null


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
	character['metadata'] = {'file': character_file}
	return character



func new_character():
	# This event creates and selects the new timeline
	master_tree.add_character(create_character()['metadata'], true)


# Saving and Loading
func generate_character_data_to_save():
	var default_speaker: bool = character_editor['default_speaker'].pressed
	var portraits = []
	for p in $HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList.get_children():
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


func save_character():
	var path = DialogicUtil.get_path('CHAR_DIR', character_editor['file'].text)
	var info_to_save = generate_character_data_to_save()
	if info_to_save['id']:
		var file = File.new()
		file.open(path, File.WRITE)
		file.store_line(to_json(info_to_save))
		file.close()
		opened_character_data = info_to_save


func load_character(path):
	var data = DialogicUtil.load_json(path)
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


# Portraits
func _on_New_Portrait_Button_pressed():
	create_portrait_entry('', '', true)


func create_portrait_entry(p_name = '', path = '', grab_focus = false):
	var p = portrait_entry.instance()
	p.editor_reference = editor_reference
	p.image_node = $HBoxContainer/VBoxContainer/Control/TextureRect
	var p_list = $HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList
	p_list.add_child(p)
	if p_name != '':
		p.get_node("NameEdit").text = p_name
	if path != '':
		p.get_node("PathEdit").text = path
	if grab_focus:
		p.get_node("NameEdit").grab_focus()
		p._on_ButtonSelect_pressed()
	return p
