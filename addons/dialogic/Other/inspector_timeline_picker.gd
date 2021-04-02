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
	prints("switchting", timeline, dialogic_editor_plugin, dialogic_editor_view)
	if (dialogic_editor_plugin != null):
		dialogic_editor_plugin.get_editor_interface().set_main_screen_editor("Dialogic")
		
	if (dialogic_editor_view != null and dialogic_editor_view.master_tree != null):
		dialogic_editor_view.master_tree.show_timeline_editor()
		dialogic_editor_view.master_tree.select_timeline_item(timeline)
	pass
