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
	'preview_editor': $VBoxContainer/HBoxContainer/ExtraInfoPreview,
	'preview_title': $VBoxContainer/HBoxContainer/ExtraInfoPreview/Title,
	'preview_text': $VBoxContainer/HBoxContainer/ExtraInfoPreview/Text,
	'preview_extra': $VBoxContainer/HBoxContainer/ExtraInfoPreview/Extra
}

func _ready():
	editor_reference = find_parent('EditorView')
	reset_editor()
	nodes['name'].connect('text_changed', self, '_on_name_changed')
	nodes['name'].connect('focus_exited', self, '_update_name_on_tree')


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
	
	# Show the preview fields if the option is enabled
	var config = DialogicResources.get_settings_config()
	var is_preview_enabled = config.get_value('dialog', 'translations_preview')
	nodes['preview_editor'].visible = is_preview_enabled
	
	# Update the preview fields if the option is enabled
	if config.get_value('dialog', 'translations_preview'):
		update_preview('preview_title', nodes['extra_title'].text)
		update_preview('preview_text', nodes['extra_text'].text)
		update_preview('preview_extra', nodes['extra_extra'].text)
	

func reset_editor():
	nodes['name'].text = ''
	nodes['extra_title'].text = ''
	nodes['extra_text'].text = ''
	nodes['extra_extra'].text = ''


func _on_name_changed(text):
	if current_definition != null:
		save_definition()


func _input(event):
	if event is InputEventKey and event.pressed:
		if nodes['name'].has_focus():
			if event.scancode == KEY_ENTER:
				nodes['name'].release_focus()


func _update_name_on_tree():
	var item = master_tree.get_selected()
	item.set_text(0, nodes['name'].text)
	if current_definition != null:
		save_definition()
		master_tree.build_definitions(current_definition['id'])


func create_glossary_entry() -> String:
	var id = DialogicUtil.generate_random_id()
	DialogicResources.set_default_definition_glossary(id, 'New glossary entry', '', '', '')
	return id

func save_definition():
	if current_definition != null and current_definition['id'] != '':
		DialogicResources.set_default_definition_glossary(current_definition['id'], nodes['name'].text, nodes['extra_title'].text, nodes['extra_text'].text, nodes['extra_extra'].text)


func _on_Title_text_changed(new_text: String) -> void:
	# Update the preview field if the option is enabled
	update_preview('preview_title', new_text)

func _on_Text_text_changed() -> void:
	# Update the preview field if the option is enabled
	var new_text = nodes['extra_text'].text
	update_preview('preview_text', new_text)


func _on_Extra_text_changed(new_text: String) -> void:
	# Update the preview field if the option is enabled
	update_preview('preview_extra', new_text)


func update_preview(node: String, text: String):
	var config = DialogicResources.get_settings_config()
	if config.get_value('dialog', 'translations_preview'):
		nodes[node].text = DialogicResources.translate(text)
	
