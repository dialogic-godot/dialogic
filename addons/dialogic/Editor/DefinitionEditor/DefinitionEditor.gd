tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTree')
var current_section = ''

onready var nodes = {
	'name' : $VBoxContainer/HBoxContainer/VBoxContainer/Name,
	'type': $VBoxContainer/HBoxContainer/VBoxContainer/TypeMenuButton,
	'extra_editor': $VBoxContainer/HBoxContainer/ExtraInfo,
	'value_editor': $VBoxContainer/HBoxContainer/Value,
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
	var item = master_tree.get_selected()
	item.set_text(0, text)


func _on_type_selected(index):
	nodes['type'].select(index)
	var item = master_tree.get_selected()
	item.set_icon(0, get_icon("Variant", "EditorIcons"))
	if index == 1:
		item.set_icon(0, get_icon("ScriptCreateDialog", "EditorIcons"))
	show_sub_editor(index)


func show_sub_editor(type):
	nodes['extra_editor'].visible = false
	nodes['value_editor'].visible = false
	if type == 0:
		nodes['value_editor'].visible = true
	if type == 1:
		nodes['extra_editor'].visible = true


func get_definition(key, default):
	if current_section != '':
		var config = ConfigFile.new()
		config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
		if config.has_section(current_section):
			return config.get_value(current_section, key, default)
	else:
		return default


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


func save_definition():
	if current_section != '':
		var config = ConfigFile.new()
		var err = config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
		if err == OK:
			config.set_value(current_section, 'name', nodes['name'].text)
			config.set_value(current_section, 'type', nodes['type'].selected)
			config.save(DialogicUtil.get_path('DEFINITIONS_FILE'))
