tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_definition = null

onready var nodes = {
	'name' : $VBoxContainer/HBoxContainer/VBoxContainer/Name,
	'value_editor': $VBoxContainer/HBoxContainer/Value,
	'value': $VBoxContainer/HBoxContainer/Value/ValueInput,
	}

func _ready():
	reset_editor()
	nodes['name'].connect('text_changed', self, '_on_name_changed')

func is_selected(id: String):
	return current_definition != null and current_definition['id'] == id

func load_definition(id):
	current_definition = DialogicResources.get_default_definition_item(id)
	reset_editor()
	nodes['name'].editable = true
	nodes['name'].text = current_definition['name']
	nodes['value'].text = current_definition['value']

func reset_editor():
	nodes['name'].text = ''
	nodes['value'].text = ''


func _on_name_changed(text):
	var item = master_tree.get_selected()
	item.set_text(0, text)
	if current_definition != null:
		save_definition()
		master_tree.build_definitions(current_definition['id'])
	nodes['name'].grab_focus()


func create_value() -> String:
	var id = DialogicUtil.generate_random_id()
	DialogicResources.set_default_definition_variable(id, 'New value', '')
	return id


func save_definition():
	if current_definition != null and current_definition['id'] != '':
		DialogicResources.set_default_definition_variable(current_definition['id'], nodes['name'].text, nodes['value'].text)
