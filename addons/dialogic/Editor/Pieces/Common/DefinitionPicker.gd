tool
extends MenuButton

var default_text = '[ Select a definition ]'

func _ready():
	get_popup().connect("index_pressed", self, '_on_entry_selected')
	get_popup().clear()
	connect("about_to_show", self, "_on_MenuButton_about_to_show")


func _on_MenuButton_about_to_show():
	get_popup().clear()
	var index = 0
	for d in DialogicUtil.get_default_definition_list():
		if d['type'] == 0:
			get_popup().add_item(d['name'])
			get_popup().set_item_metadata(index, {
				'section': d['section'],
			})
			index += 1


func _on_entry_selected(index):
	var _text = get_popup().get_item_text(index)
	var metadata = get_popup().get_item_metadata(index)
	text = _text


func load_definition(section):
	if section != '':
		for d in DialogicUtil.get_default_definition_list():
			if d['section'] == section:
				text = d['name']
	else:
		text = default_text
