tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var texture_rect = $Box/TextureRect

# used to connect the signals
func _ready():
	pass

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if event_data['background']:
		if not event_data['background'].ends_with('.tscn'):
			emit_signal("request_set_body_enabled", true)
			texture_rect.texture = load(event_data['background'])
		else:
			emit_signal("request_set_body_enabled", false)
			if editor_reference and editor_reference.editor_interface:
				editor_reference.editor_interface.get_resource_previewer().queue_resource_preview(event_data['background'], self, "show_scene_preview", null)
	else:
		emit_signal("request_set_body_enabled", false)

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func show_scene_preview(path:String, preview:Texture, user_data):
	if preview:
		texture_rect.texture = preview
		emit_signal("request_set_body_enabled", true)
		

