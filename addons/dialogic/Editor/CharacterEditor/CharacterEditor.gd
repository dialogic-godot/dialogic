tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var opened_character_data
var portrait_entry = load("res://addons/dialogic/Editor/CharacterEditor/PortraitEntry.tscn")
onready var nodes = {
	'editor': $HBoxContainer/Container,
	'name': $HBoxContainer/Container/Name/LineEdit,
	'description': $HBoxContainer/Container/Description/TextEdit,
	'file': $HBoxContainer/Container/FileName/LineEdit,
	'color': $HBoxContainer/Container/Color/ColorPickerButton,
	'mirror_portraits_checkbox' : $HBoxContainer/VBoxContainer/HBoxContainer/MirrorOption/MirrorPortraitsCheckBox,
	'default_speaker': $HBoxContainer/Container/Actions/DefaultSpeaker,
	'display_name_checkbox': $HBoxContainer/Container/Name/CheckBox,
	'display_name': $HBoxContainer/Container/DisplayName/LineEdit,
	'new_portrait_button': $HBoxContainer/Container/ScrollContainer/VBoxContainer/HBoxContainer/Button,
	'portrait_preview': $HBoxContainer/VBoxContainer/Control/TextureRect,
	'scale': $HBoxContainer/VBoxContainer/HBoxContainer/Scale,
	'offset_x': $HBoxContainer/VBoxContainer/HBoxContainer/OffsetX,
	'offset_y': $HBoxContainer/VBoxContainer/HBoxContainer/OffsetY,
}


func _ready():
	nodes['new_portrait_button'].connect('pressed', self, '_on_New_Portrait_Button_pressed')
	nodes['display_name_checkbox'].connect('toggled', self, '_on_display_name_toggled')
	nodes['name'].connect('text_changed', self, '_on_name_changed')
	nodes['color'].connect('color_changed', self, '_on_color_changed')
	var style = get('custom_styles/bg')
	style.set('bg_color', get_color("base_color", "Editor"))


func is_selected(file: String):
	return nodes['file'].text == file

func _on_display_name_toggled(button_pressed):
	$HBoxContainer/Container/DisplayName.visible = button_pressed


func _on_name_changed(value):
	var item = master_tree.get_selected()
	item.set_text(0, value)
	save_character()
	master_tree.build_characters(nodes['file'].text)


func _on_color_changed(color):
	var item = master_tree.get_selected()
	item.set_icon_modulate(0, color)


func clear_character_editor():
	nodes['file'].text = ''
	nodes['name'].text = ''
	nodes['description'].text = ''
	nodes['color'].color = Color('#ffffff')
	nodes['mirror_portraits_checkbox'].pressed = false
	nodes['default_speaker'].pressed = false
	nodes['display_name_checkbox'].pressed = false
	nodes['display_name'].text = ''
	nodes['portraits'] = []
	nodes['scale'].value = 100
	nodes['offset_x'].value = 0
	nodes['offset_y'].value = 0

	# Clearing portraits
	for p in $HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList.get_children():
		p.queue_free()
	nodes['portrait_preview'].texture = null


# Character Creation
func create_character():
	var character_file = 'character-' + str(OS.get_unix_time()) + '.json'
	var character = {
		'color': '#ffffff',
		'id': character_file,
		'default_speaker': false,
		'portraits': [],
		'mirror_portraits' :false
	}
	DialogicResources.set_character(character)
	character['metadata'] = {'file': character_file}
	return character


func new_character():
	# This event creates and selects the new character
	master_tree.build_characters(create_character()['metadata']['file'])


# Saving and Loading
func generate_character_data_to_save():
	var default_speaker: bool = nodes['default_speaker'].pressed
	var portraits = []
	for p in $HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList.get_children():
		var entry = {}
		entry['name'] = p.get_node("NameEdit").text
		entry['path'] = p.get_node("PathEdit").text
		portraits.append(entry)
	var info_to_save = {
		'id': nodes['file'].text,
		'description': nodes['description'].text,
		'color': '#' + nodes['color'].color.to_html(),
		'mirror_portraits': nodes["mirror_portraits_checkbox"].pressed,
		'default_speaker': default_speaker,
		'portraits': portraits,
		'display_name_bool': nodes['display_name_checkbox'].pressed,
		'display_name': nodes['display_name'].text,
		'scale': nodes['scale'].value,
		'offset_x': nodes['offset_x'].value,
		'offset_y': nodes['offset_y'].value,
	}
	# Adding name later for cases when no name is provided
	if nodes['name'].text != '':
		info_to_save['name'] = nodes['name'].text
	
	return info_to_save


func save_character():
	var info_to_save = generate_character_data_to_save()
	if info_to_save['id']:
		DialogicResources.set_character(info_to_save)
		opened_character_data = info_to_save



func load_character(filename: String):
	clear_character_editor()
	var data = DialogicResources.get_character_json(filename)
	opened_character_data = data
	nodes['file'].text = data['id']
	nodes['default_speaker'].pressed = false
	if data.has('name'):
		nodes['name'].text = data['name']
	if data.has('description'):
		nodes['description'].text = data['description']
	if data.has('color'):
		nodes['color'].color = Color(data['color'])
	if data.has('default_speaker'):
		if data['default_speaker']:
			nodes['default_speaker'].pressed = true
	
	if data.has('display_name_bool'):
		nodes['display_name_checkbox'].pressed = data['display_name_bool']
	if data.has('display_name'):
		nodes['display_name'].text = data['display_name']
	if data.has('scale'):
		nodes['scale'].value = float(data['scale'])
	
	if data.has('offset_x'):
		nodes['offset_x'].value = data['offset_x']
		nodes['offset_y'].value = data['offset_y']
	
	if data.has('mirror_portraits'):
		nodes['mirror_portraits_checkbox'].pressed = data['mirror_portraits']
		nodes['portrait_preview'].flip_h = data['mirror_portraits']
	else:
		nodes['mirror_portraits_checkbox'].pressed = false
		nodes['portrait_preview'].flip_h = false
	
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
	p.image_node = nodes['portrait_preview']
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


func _on_MirrorPortraitsCheckBox_toggled(button_pressed):
	nodes['portrait_preview'].flip_h = button_pressed
