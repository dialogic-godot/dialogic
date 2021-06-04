tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_definition = null

onready var nodes = {
	'name' : $VBoxContainer/HBoxContainer/VBoxContainer/Name,
	'extra_editor': $VBoxContainer/HBoxContainer/ExtraInfo,
	'extra_title': $VBoxContainer/HBoxContainer/ExtraInfo/Title,
	'extra_text': $VBoxContainer/HBoxContainer/ExtraInfo/Text,
	'extra_extra': $VBoxContainer/HBoxContainer/ExtraInfo/Extra,
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
	nodes['extra_title'].text = current_definition['title']
	nodes['extra_text'].text = current_definition['text']
	nodes['extra_extra'].text = current_definition['extra']
	

func reset_editor():
	nodes['name'].text = ''
	nodes['extra_title'].text = ''
	nodes['extra_text'].text = ''
	nodes['extra_extra'].text = ''

func _on_name_changed(text):
	var item = master_tree.get_selected()
	item.set_text(0, text)
	if current_definition != null:
		save_definition()
		master_tree.build_definitions(current_definition['id'])
	nodes['name'].grab_focus()


func create_glossary_entry() -> String:
	var id = DialogicUtil.generate_random_id()
	DialogicResources.set_default_definition_glossary(id, 'New glossary entry', '', '', '')
	return id

func save_definition():
	if current_definition != null and current_definition['id'] != '':
		DialogicResources.set_default_definition_glossary(current_definition['id'], nodes['name'].text, nodes['extra_title'].text, nodes['extra_text'].text, nodes['extra_extra'].text)
