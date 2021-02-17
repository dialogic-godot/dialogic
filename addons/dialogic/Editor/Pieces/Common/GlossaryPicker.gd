tool
extends MenuButton

func _ready():
	get_popup().connect("index_pressed", self, '_on_entry_selected')
	get_popup().clear()
	connect("about_to_show", self, "_on_MenuButton_about_to_show")


func _on_MenuButton_about_to_show():
	var glossary = DialogicUtil.load_glossary()
	get_popup().clear()
	
	var index = 0
	for c in glossary:
		if glossary[c]['type'] != DialogicUtil.GLOSSARY_EXTRA and glossary[c]['type'] != DialogicUtil.GLOSSARY_NONE:
			get_popup().add_item(glossary[c]['name'] + ' (' + glossary_type_to_human(glossary[c]['type']) + ')')
			get_popup().set_item_metadata(index, {
				'file': glossary[c]['file'],
				'type': glossary[c]['type']
			})
			index += 1


func _on_entry_selected(index):
	var _text = get_popup().get_item_text(index)
	var metadata = get_popup().get_item_metadata(index)
	text = _text


static func glossary_type_to_human(value: int) -> String:
	var types = {
		DialogicUtil.GLOSSARY_NONE: 'None',
		DialogicUtil.GLOSSARY_EXTRA: 'Extra Information',
		DialogicUtil.GLOSSARY_NUMBER: 'Number',
		DialogicUtil.GLOSSARY_STRING: 'Text'
	}
	return types[value]
