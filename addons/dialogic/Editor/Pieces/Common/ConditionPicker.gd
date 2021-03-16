tool
extends MenuButton

var options = [
	{
		"text": "[ Equal to ]",
		"condition": "=="
	},
	{
		"text": "[ Different from ]",
		"condition": "!="
	},
	{
		"text": "[ Greater than ]",
		"condition": ">"
	},
	{
		"text": "[ Greater or equal to ]",
		"condition": ">="
	},
	{
		"text": "[ Less than ]",
		"condition": "<"
	},
	{
		"text": "[ Less or equal to ]",
		"condition": "<="
	}
]

func _ready():
	get_popup().connect("index_pressed", self, '_on_entry_selected')
	get_popup().clear()
	connect("about_to_show", self, "_on_MenuButton_about_to_show")


func _on_MenuButton_about_to_show():
	get_popup().clear()
	var index = 0
	for o in options:
		get_popup().add_item(o['text'])
		get_popup().set_item_metadata(index, o)
		index += 1


func _on_entry_selected(index):
	var _text = get_popup().get_item_text(index)
	var metadata = get_popup().get_item_metadata(index)
	text = _text


func load_condition(condition):
	if condition != '':
		for o in options:
			if (o['condition'] == condition):
				text = o['text']
	else:
		text = options[0]['text']
