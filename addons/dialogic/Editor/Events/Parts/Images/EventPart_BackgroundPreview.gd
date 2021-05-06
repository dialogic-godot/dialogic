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
			$Box.show()
			texture_rect.texture = load(event_data['background'])
		else:
			$Box.hide()
	else:
		$Box.hide()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''
