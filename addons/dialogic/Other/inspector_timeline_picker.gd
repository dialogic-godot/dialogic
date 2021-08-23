extends EditorInspectorPlugin

var TimelinePicker = preload("res://addons/dialogic/Other/timeline_picker.gd")
var dialogic_editor_plugin = null
var dialogic_editor_view = null


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
			var picker = TimelinePicker.new()
			picker.editor_inspector_plugin = self
			add_property_editor(path, picker)
			# Inform the editor to remove the default property editor for
			# this property type.
			return true
		return false


func switch_to_dialogic_timeline(timeline: String):
	if (dialogic_editor_plugin != null):
		var master_tree = dialogic_editor_view.get_node('MainPanel/MasterTreeContainer/MasterTree')
		dialogic_editor_plugin.get_editor_interface().set_main_screen_editor("Dialogic")

		master_tree.timeline_editor.batches.clear()
		master_tree.timeline_editor.load_timeline(timeline)
		master_tree.show_timeline_editor()
