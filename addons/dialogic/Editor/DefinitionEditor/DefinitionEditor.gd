tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTree')
var current_section = ''

onready var nodes = {
	'name' : $VBoxContainer/HBoxContainer/VBoxContainer/Name,
	'type': $VBoxContainer/HBoxContainer/VBoxContainer/TypeMenuButton,
	'extra_editor': $VBoxContainer/HBoxContainer/VBoxContainer/ExtraInfo,
	'number_editor': $VBoxContainer/HBoxContainer/VBoxContainer/Number,
	'string_editor': $VBoxContainer/HBoxContainer/VBoxContainer/Text,
}

func _ready():
	reset_editor()
	nodes['name'].connect('text_changed', self, '_on_name_changed')
	nodes['type'].connect('item_selected', self, '_on_type_selected')


func load_definition(section):
	current_section = section
	reset_editor()
	nodes['name'].editable = true
	nodes['name'].text = get_definition('name', 'Unnamed')
	var type = get_definition('type', 0)
	nodes['type'].select(type)
	show_sub_editor(type)


func reset_editor():
	nodes['name'].text = ''
	nodes['type'].select(get_definition('type', 0))


func _on_name_changed(text):
	save_definition('name', text)
	var item = master_tree.get_selected()
	item.set_text(0, text)


func _on_type_selected(index):
	nodes['type'].select(index)
	save_definition('type', index)
	var item = master_tree.get_selected()
	if index == 1:
		item.set_icon(0, get_icon("ScriptCreateDialog", "EditorIcons"))
	elif index == 2:
		item.set_icon(0, get_icon("int", "EditorIcons"))
	elif index == 3:
		item.set_icon(0, get_icon("String", "EditorIcons"))
	else:
		item.set_icon(0, get_icon("GuiUnchecked", "EditorIcons"))
	show_sub_editor(index)

func show_sub_editor(type):
	nodes['extra_editor'].visible = false
	nodes['number_editor'].visible = false
	nodes['string_editor'].visible = false
	if type == 1:
		nodes['extra_editor'].visible = true
	if type == 2:
		nodes['number_editor'].visible = true
	if type == 3:
		nodes['string_editor'].visible = true


func new_definition():
	var config = ConfigFile.new()
	var section = DialogicUtil.generate_random_id()
	var err = config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
	if err == OK:
		config.set_value(section, 'name', 'New definition')
		config.set_value(section, 'type', 0)
		config.save(DialogicUtil.get_path('DEFINITIONS_FILE'))
		master_tree.add_definition({'section': section,'name': 'New definition', 'type': 0}, true)
	else:
		print('Error loading definitions')


func get_definition(key, default):
	if current_section != '':
		var config = ConfigFile.new()
		config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
		if config.has_section(current_section):
			return config.get_value(current_section, key, default)
	else:
		return default


func save_definition(key, value):	
	if current_section != '':
		var config = ConfigFile.new()
		var section = DialogicUtil.generate_random_id()
		var err = config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
		if err == OK:
			config.set_value(current_section, key, value)
			config.save(DialogicUtil.get_path('DEFINITIONS_FILE'))
