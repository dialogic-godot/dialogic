tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var title_input = $Title/Input
onready var title_check = $Title/Check
onready var text_input = $Text/Input
onready var text_check = $Text/Check
onready var extra_input = $Extra/Input
onready var extra_check = $Extra/Check

# used to connect the signals
func _ready():
	title_input.connect("text_changed", self, "_on_TitleField_text_changed")
	text_input.connect("text_changed", self, "_on_TextField_text_changed")
	extra_input.connect("text_changed", self, "_on_ExtraField_text_changed")
	
	title_check.connect("toggled", self, "_on_TitleCheck_toggled")
	text_check.connect("toggled", self, "_on_TextCheck_toggled")
	extra_check.connect("toggled", self, "_on_ExtraCheck_toggled")


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	emit_signal("request_set_body_enabled", event_data['glossary_id'] != '')
	
	$Title.visible = event_data['glossary_id'] != ''
	$Text.visible = event_data['glossary_id'] != ''
	$Extra.visible = event_data['glossary_id'] != ''
	
	if event_data['glossary_id']:
		var glossary_default 
		for d in DialogicResources.get_default_definitions()['glossary']:
			if d['id'] == event_data['glossary_id']:
				glossary_default = d
		title_input.placeholder_text = glossary_default['title']
		text_input.placeholder_text = glossary_default['text']
		extra_input.placeholder_text = glossary_default['extra']
	
	# Now update the ui nodes to display the data. 
	if event_data['title'] == "[No Change]":
		title_check.pressed = true
		title_input.text = ""
	else:
		title_check.pressed = false
		title_input.text = event_data['title']
	if event_data['text'] == "[No Change]":
		text_check.pressed = true
		text_input.text = ""
	else:
		text_check.pressed = false
		text_input.text = event_data['text']
	if event_data['extra'] == "[No Change]":
		extra_check.pressed = true
		extra_input.text = ""
	else:
		extra_check.pressed = false
		extra_input.text = event_data['extra']
	

# has to return the wanted preview, only useful for body parts
func get_preview():
	if event_data['glossary_id']:
		var text := ""
		if event_data['title'] != "[No Change]":
			text += "Changes title to '"+event_data['title']+"'. "
		if event_data['extra'] != "[No Change]":
			text += "Changes extra to '"+event_data['extra']+"'. "
		if event_data['text'] != "[No Change]":
			text += "Changes text to '"+event_data['text']+"'. "
		return text
	return ''

func _on_TitleField_text_changed(text):
	event_data['title'] = text
	
	# informs the parent about the changes!
	data_changed()

func _on_TextField_text_changed(text):
	event_data['text'] = text
	
	# informs the parent about the changes!
	data_changed()

func _on_ExtraField_text_changed(text):
	event_data['extra'] = text
	
	# informs the parent about the changes!
	data_changed()

func _on_TitleCheck_toggled(toggle):
	if toggle:
		event_data['title'] = "[No Change]"
		title_input.editable = false
	else:
		event_data['title'] = title_input.text
		title_input.editable = true
	
	# informs the parent about the changes!
	data_changed()

func _on_TextCheck_toggled(toggle):
	if toggle:
		event_data['text'] = "[No Change]"
		text_input.editable = false
	else:
		event_data['text'] = text_input.text
		text_input.editable = true
	
	# informs the parent about the changes!
	data_changed()

func _on_ExtraCheck_toggled(toggle):
	if toggle:
		event_data['extra'] = "[No Change]"
		extra_input.editable = false
	else:
		event_data['extra'] = extra_input.text
		extra_input.editable = true
	
	# informs the parent about the changes!
	data_changed()
