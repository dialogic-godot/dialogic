tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var text_editor = $HBoxContainer/TextEdit
onready var translated_text_label = $TranslatedText
onready var edit_translation_button = $HBoxContainer/EditTranslationButton

var timeline_area = null
var text_gap = 50

# used to connect the signals
func _ready():
	text_gap = (text_gap * DialogicUtil.get_editor_scale(self))
	
	# signals
	text_editor.connect("text_changed", self, "_on_TextEditor_text_changed")
	text_editor.connect("focus_entered", self, "_on_TextEditor_focus_entered")
	
	# stylistig setup
	text_editor.syntax_highlighting = true
	text_editor.add_color_region('[', ']', get_color("axis_z_color", "Editor"))
	text_editor.set('custom_colors/number_color', get_color("font_color", "Editor"))
	text_editor.set('custom_colors/function_color', get_color("font_color", "Editor"))
	text_editor.set('custom_colors/member_variable_color', get_color("font_color", "Editor"))
	text_editor.set('custom_colors/symbol_color', get_color("font_color", "Editor"))
	
	timeline_area = find_parent('TimelineArea')
	timeline_area.connect('resized', self, '_set_new_min_size')
	
	_set_new_min_size()
	


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
	_set_new_min_size()

	_update_translation_preview()

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
	
	text = DTS.translate(text)
	
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
	
	_set_new_min_size()
	
	_update_translation_preview()
	
	# informs the parent about the changes!
	data_changed()


func _update_translation_preview():
	if not DialogicResources.get_settings_value("dialog", "in_editor_translation", false):
		translated_text_label.visible = false
		edit_translation_button.visible = false
		return
	
	edit_translation_button.visible = true
	var translated_text = DTS.translate(text_editor.text)
	if translated_text != text_editor.text:
		translated_text_label.visible = true
		translated_text_label.text = translated_text
	else:
		translated_text_label.text = ""
		translated_text_label.visible = false


func _set_new_min_size():
	# Reset
	text_editor.rect_min_size = Vector2(0,0)
	# Getting new sizes
	var extra_vertical = 1.1
	
	# Getting the longest string and making that the width of the dialog bubble
	# also check how many lines wrap (and how often)
	var count_wrapped_lines = 0
	var longest_string = ''
	for l in text_editor.text.split('\n'):
		if l.length() > longest_string.length():
			longest_string = l
		if get_font("normal_font").get_string_size(l).x > get_max_x_size():
			count_wrapped_lines += get_font("normal_font").get_string_size(l).x/(get_max_x_size())
	
	# set the height
	if text_editor.get_line_count() > 1:
		extra_vertical = 1.22
	text_editor.rect_min_size.y = get_font("normal_font").get_height() * ((text_editor.get_line_count() + 1 + count_wrapped_lines) * extra_vertical)
	
	# set the width
	text_editor.rect_min_size.x = get_font("normal_font").get_string_size(longest_string).x + text_gap
	if text_editor.rect_min_size.x > get_max_x_size():
		text_editor.rect_min_size.x = get_max_x_size()
	
	text_editor.rect_size.x = text_editor.rect_min_size.x
	
	_set_translated_text_min_size()

func _set_translated_text_min_size():
	if translated_text_label.visible == false:
		return
	
	translated_text_label.rect_min_size.x = get_max_x_size() - 1
	translated_text_label.rect_size.x = translated_text_label.rect_min_size.x


func get_max_x_size():
	return timeline_area.rect_size.x - (text_editor.rect_global_position.x - timeline_area.rect_global_position.x) - text_gap


func _on_TextEditor_focus_entered() -> void:
	if (Input.is_mouse_button_pressed(BUTTON_LEFT)):
		emit_signal("request_selection")


func _on_TextEdit_focus_exited():
	# Remove text selection to visually notify the user that the text will not 
	# be copied if they use a hotkey like CTRL + C 
	text_editor.deselect()


func focus():
	text_editor.grab_focus()


func _on_TranslationTextEditPopupValueSaved(var value : String) -> void:
	translated_text_label.text = value


func _on_EditTranslationButton_key_saved(value) -> void:
	text_editor.text = value
	_on_TextEditor_text_changed()
