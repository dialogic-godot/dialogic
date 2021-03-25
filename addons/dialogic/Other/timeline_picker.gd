tool
extends EditorProperty


# The main control for editing the property.
var timelines_dropdown = MenuButton.new()
# An internal value of the property.
var current_value = ''
# A guard against internal changes when the property is updated.
var updating = false


func _init():
	# Add the control as a direct child of EditorProperty node.
	add_child(timelines_dropdown)
	# Make sure the control is able to retain the focus.
	add_focusable(timelines_dropdown)
	# Setup the initial state and connect to the signal to track changes.
	timelines_dropdown.connect("about_to_show", self, "_about_to_show_menu")
	timelines_dropdown.get_popup().connect("index_pressed", self, '_on_timeline_selected')


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
	emit_changed(get_edited_property(), current_value)


func update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	if (new_value == current_value):
		return

	# Update the control with the new value.
	updating = true
	current_value = new_value
	# Checking for the display name
	for c in DialogicUtil.get_timeline_list():
		if c['file'] == current_value:
			timelines_dropdown.text = c['name']
	updating = false
