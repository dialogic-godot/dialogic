extends EditorInspectorPlugin

var TimelinePicker = preload("res://addons/dialogic/Other/timeline_picker.gd")


func can_handle(object):
	# We support all objects in this example.
	return true


func parse_property(object, type, path, hint, hint_text, usage):
	# We check for this hint text. It would look like: export(String, "TimelineDropdown")
	if hint_text == "TimelineDropdown":
		# We handle properties of type string.
		if type == TYPE_STRING:
			# Create an instance of the custom property editor and register
			# it to a specific property path.
			add_property_editor(path, TimelinePicker.new())
			# Inform the editor to remove the default property editor for
			# this property type.
			return true
		return false
