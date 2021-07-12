tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
var text_height = 21

## node references
onready var text_editor = $TextEdit


# used to connect the signals
func _ready():
	# signals
	text_editor.connect("text_changed", self, "_on_TextEditor_text_changed")
	text_editor.connect("focus_entered", self, "_on_TextEditor_focus_entered")
	
	# stylistig setup
	text_editor.syntax_highlighting = true
	text_editor.add_color_region('[', ']', get_color("axis_z_color", "Editor"))
	text_editor.set('custom_colors/number_color', get_color("font_color", "Editor"))
	
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	text_height = text_height * _scale
	text_editor.set("rect_min_size", Vector2(0, text_height*2))
	

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	# in case this is a text event
	if data['event_id'] == 'dialogic_001':
		text_editor.text = event_data['text']
	# in case this is a question event
	elif data['event_id'] == 'dialogic_010':
		text_editor.text = event_data['question']
	# otherwise
	else:
		text_editor.text = event_data['text']
	
	# resize the text_editor to the correct size 
	text_editor.rect_min_size.y = text_height * (2 + text_editor.text.count('\n'))

# has to return the wanted preview, only useful for body parts
func get_preview():
	var max_preview_characters = 35
	var text = ''
	if event_data['event_id'] == 'dialogic_001':
		text = event_data['text']
	# in case this is a question event
	elif event_data['event_id'] == 'dialogic_010':
		text = event_data['question']
	# otherwise
	else:
		text = event_data['text']
	text = text.replace('\n', '[br]')
	var preview = text.substr(0, min(max_preview_characters, len(text)))
	if (len(text) > max_preview_characters):
		preview += "..."
	
	return preview

func _on_TextEditor_text_changed():
	# in case this is a text event
	if event_data['event_id'] == 'dialogic_001':
		event_data['text'] = text_editor.text
	# in case this is a question event
	elif event_data['event_id'] == 'dialogic_010':
		event_data['question'] = text_editor.text
	# otherwise
	else:
		event_data['text'] = text_editor.text
	text_editor.rect_min_size.y = text_height * (2 + text_editor.text.count('\n'))
	
	# informs the parent about the changes!
	data_changed()

func _on_TextEditor_focus_entered() -> void:
	if (Input.is_mouse_button_pressed(BUTTON_LEFT)):
		emit_signal("request_selection")


func _on_TextEdit_focus_exited():
	# Remove text selection to visually notify the user that the text will not 
	# be copied if they use a hotkey like CTRL + C 
	$TextEdit.deselect()
