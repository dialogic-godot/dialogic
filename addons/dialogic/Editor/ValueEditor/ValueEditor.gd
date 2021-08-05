tool
extends ScrollContainer

var editor_reference:EditorView
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_definition = null

onready var name_node = $VBoxContainer/HBoxContainer/VBoxContainer/Name
onready var value_node = $VBoxContainer/HBoxContainer/Value/ValueInput

var tmp_name = ""

var tmp_value = ""

func _ready():
	reset_editor()
	
	name_node.connect('text_entered', self, '_on_name_entered')

	value_node.connect("text_entered", self, "_on_value_entered")


func is_selected(id: String):
	return current_definition != null and current_definition['id'] == id
	
func load_value(name):
	name_node.editable = true
	name_node.text = name
	
	value_node.text = editor_reference.res_values[name]
	
	tmp_name = name

func reset_editor():
	name_node.text = ''
	value_node.text = ''

func _on_name_entered(text):
	if text == "":
		name_node.text = tmp_name
		return
	
	if text == tmp_name:
		return
	
	if editor_reference.change_value_name(tmp_name, text):
		master_tree.set_selected_item_name(text)
			
		tmp_name = text
	else:
		name_node.text = tmp_name
		
func _on_value_entered(text):
	if text == "":
		value_node.text = tmp_value
		return
		
	if text == tmp_value:
		return
		
	editor_reference.set_value(name_node.text, text)
	
	value_node.release_focus()
