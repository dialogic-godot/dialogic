tool
extends ScrollContainer

var editor_reference
onready var master_tree = get_node('../MasterTree')
var current_definition = null

onready var nodes = {
	'name' : $VBoxContainer/HBoxContainer/VBoxContainer/Name,
	'type': $VBoxContainer/HBoxContainer/VBoxContainer/TypeMenuButton,
	'extra_editor': $VBoxContainer/HBoxContainer/ExtraInfo,
	'value_editor': $VBoxContainer/HBoxContainer/Value,
	'value': $VBoxContainer/HBoxContainer/Value/ValueInput,
	'extra_title': $VBoxContainer/HBoxContainer/ExtraInfo/Title,
	'extra_text': $VBoxContainer/HBoxContainer/ExtraInfo/Text,
	'extra_extra': $VBoxContainer/HBoxContainer/ExtraInfo/Extra,
}

func _ready():
	reset_editor()
	nodes['name'].connect('text_changed', self, '_on_name_changed')
	nodes['type'].connect('item_selected', self, '_on_type_selected')


func is_selected(id: String):
	return current_definition != null and current_definition['id'] == id

func load_definition(id):
	current_definition = DialogicResources.get_default_definition_item(id)
	reset_editor()
	nodes['name'].editable = true
	nodes['name'].text = current_definition['name']
	var type = current_definition['type']
	nodes['type'].select(type)
	if type == 0:
		nodes['value'].text = current_definition['value']
	if type == 1:
		nodes['extra_title'].text = current_definition['title']
		nodes['extra_text'].text = current_definition['text']
		nodes['extra_extra'].text = current_definition['extra']
	show_sub_editor(type)


func reset_editor():
	nodes['name'].text = ''
	nodes['value'].text = ''
	nodes['extra_title'].text = ''
	nodes['extra_text'].text = ''
	nodes['extra_extra'].text = ''
	var type = 0
	if current_definition != null:
		type = current_definition['type']
	nodes['type'].select(type)


func _on_name_changed(text):
	var item = master_tree.get_selected()
	item.set_text(0, text)
	if current_definition != null:
		save_definition()
		master_tree.build_definitions(current_definition['id'])


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


func new_definition():
	var id = DialogicUtil.generate_random_id()
	DialogicResources.set_default_definition_variable(id, 'New definition', '')
	master_tree.build_definitions(id)


func save_definition():
	if current_definition != null and current_definition['id'] != '':
		var type: int = nodes['type'].selected
		if type == 0:
			DialogicResources.set_default_definition_variable(current_definition['id'], nodes['name'].text, nodes['value'].text)
		if type == 1:
			DialogicResources.set_default_definition_glossary(current_definition['id'], nodes['name'].text, nodes['extra_title'].text, nodes['extra_text'].text, nodes['extra_extra'].text)
