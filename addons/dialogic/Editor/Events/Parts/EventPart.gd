tool
extends Control

# has to be set by the parent before adding it to the tree
var editor_reference
#var editorPopup

var event_data = {}

signal data_changed

# emit this to set the enabling of the body
signal request_set_body_enabled(enabled)

# emit these if you want the body to be closed/opened
signal request_open_body
signal request_close_body

# emit these if you want the event to be selected
signal request_selection

# emit this if you want a warning to be displayed/hidden
signal set_warning(text)
signal remove_warning()


# when the node is ready
func _ready():
	pass

# to be overwritten by the subclasses
func load_data(data:Dictionary):
	event_data = data


# to be overwritten by body-parts that provide a preview
func get_preview_text():
	return ''


# has to be called everytime the data got changed
func data_changed():
	emit_signal("data_changed", event_data)

