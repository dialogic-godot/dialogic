tool
extends Control

var text_height = 21
var editor_reference
var preview: String = ''
onready var toggler = get_node("PanelContainer/VBoxContainer/Header/VisibleToggle")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'character': '',
	'text': '',
	'portrait': '',
}

onready var character_picker = $PanelContainer/VBoxContainer/Header/CharacterAndPortraitPicker
onready var text_editor = $PanelContainer/VBoxContainer/TextEdit

func _ready():
	text_editor.syntax_highlighting = true
	text_editor.add_color_region('[', ']', get_color("axis_z_color", "Editor"))
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	text_height = text_height * _scale
	connect("gui_input", self, '_on_gui_input')
	text_editor.connect("focus_entered", self, "_on_TextEdit_focus_entered")
	text_editor.set("rect_min_size", Vector2(0, 80))
	character_picker.connect('character_changed', self , '_on_character_changed')

	var c_list = DialogicUtil.get_sorted_character_list()
	if c_list.size() == 0:
		character_picker.visible = false
	else:
		# Default Speaker
		for c in c_list:
			if c['default_speaker']:
				event_data['character'] = c['file']


func _on_character_changed(character_data: Dictionary, portrait: String) -> void:
	if character_data.keys().size() > 0:
		event_data['character'] = character_data['file']
		event_data['portrait'] = portrait
	else:
		event_data['character'] = ''
		event_data['portrait'] = ''
	update_preview()


func _on_TextEdit_text_changed() -> void:
	var text = text_editor.text
	event_data['text'] = text
	update_preview()


func load_text(text) -> void:
	get_node("VBoxContainer/TextEdit").text = text
	event_data['text'] = text
	update_preview()


func load_data(data) -> void:
	event_data = data
	text_editor.text = event_data['text']
	character_picker.set_data(event_data['character'], event_data['portrait'])
	update_preview()


func update_preview() -> String:
	var t = text_editor.text
	text_editor.rect_min_size.y = text_height * (2 + t.count('\n'))
	
	var text = event_data['text']
	var lines = text.count('\n')
	if text == '':
		return ''
	if '\n' in text:
		text = text.split('\n')[0]
	preview = text
	if preview.length() > 60:
		preview = preview.left(60) + '...'
	
	if lines > 0:
		preview += '  -  ' + str(lines + 1) + ' lines'
	return preview


func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.doubleclick:
		if event.button_index == 1:
			if toggler.pressed:
				toggler.pressed = false
			else:
				toggler.pressed = true


func _on_TextEdit_focus_entered() -> void:
	# propagate to timeline to make this text event as active selected
	# to help improve keyboard shortcut workflows
	# only maybe only do this on left click since mouse wheel and
	# touch scrolling may triggers this event too
	if (Input.is_mouse_button_pressed(BUTTON_LEFT)):
		var timeline_editor = editor_reference.get_node_or_null('MainPanel/TimelineEditor')
		if (timeline_editor != null):
			# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
			# consider to make it "public" or add a public helper function
			timeline_editor._clear_selection()
			timeline_editor._select_item(self)
	
	
func _on_saver_timer_timeout() -> void:
	update_preview()
	
	
# gets called when the user selects this node in the timeline
func on_timeline_selected() -> void:
	text_editor.grab_focus()
