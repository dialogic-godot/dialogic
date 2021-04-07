tool
extends EditorProperty

# The main controls for editing the property.
var timelines_dropdown = MenuButton.new()
var container = HBoxContainer.new()
var edit_button = Button.new()

# reference to the inspector plugin
var editor_inspector_plugin = null

# An internal value of the property.
var current_value = ''
# A guard against internal changes when the property is updated.
var updating = false

# @Override
func get_tooltip_text():
	return "Click to select a Dialogic timeline.\nPress the tool button to directly switch to the editor"


func _ready():
	edit_button.icon = get_icon("Tools", "EditorIcons")


func _init():
	# setup controls
	timelines_dropdown.rect_min_size.x = 80
	timelines_dropdown.set_h_size_flags(SIZE_EXPAND_FILL)
	timelines_dropdown.clip_text = true
	container.add_child(timelines_dropdown)
	container.add_child(edit_button)
	edit_button.flat = true
	edit_button.hint_tooltip = "Edit Timeline"
	edit_button.disabled = true
	
	# Add the container as a direct child
	add_child(container)
	
	# Make sure the control is able to retain the focus.
	add_focusable(timelines_dropdown)
	
	# Setup the initial state and connect to the signal to track changes.
	timelines_dropdown.connect("about_to_show", self, "_about_to_show_menu")
	timelines_dropdown.get_popup().connect("index_pressed", self, '_on_timeline_selected')
	edit_button.connect("pressed", self, "_on_editTimelineButton_pressed")


func _about_to_show_menu():
	# Ignore the signal if the property is currently being updated.
	if (updating):
		return

	# Adding timelines
	timelines_dropdown.get_popup().clear()
	var index = 0
	for c in DialogicUtil.get_sorted_timeline_list():
		timelines_dropdown.get_popup().add_item(c['name'])
		timelines_dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': c['color']})
		index += 1


func _on_timeline_selected(index):
	var text = timelines_dropdown.get_popup().get_item_text(index)
	var metadata = timelines_dropdown.get_popup().get_item_metadata(index)
	current_value = metadata['file']
	timelines_dropdown.text = text
	timelines_dropdown.hint_tooltip = text
	_update_edit_button(current_value)
	emit_changed(get_edited_property(), current_value)
	
	
func _on_editTimelineButton_pressed():
	if (current_value != '' and editor_inspector_plugin != null):
		editor_inspector_plugin.switch_to_dialogic_timeline(current_value)


func update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	_update_edit_button(new_value)
	
	if (new_value == current_value):
		return
		
	# Update the control with the new value.
	updating = true
	current_value = new_value
	# Checking for the display name
	timelines_dropdown.text = ''
	
	if (current_value == ''):
		timelines_dropdown.hint_tooltip = 'Click to select a timeline'
		
	for c in DialogicUtil.get_timeline_list():
		if c['file'] == current_value:
			timelines_dropdown.text = c['name']
			timelines_dropdown.hint_tooltip = c['name']
			
	updating = false
	
	_update_edit_button(current_value)
	
	
func _update_edit_button(value):
	if (value == ''):
		edit_button.disabled = true
	else:
		edit_button.disabled = false
