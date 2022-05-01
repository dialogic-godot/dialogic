tool
extends DialogicEvent

export(String) var node_path:String = "" # this probably will need a setter

# _init is the constructor
# is called everytime the resource is being created
# (including when the resource is loaded)
# ensuring to keep the same values everytime until
# you modify them
func _init() -> void:
	event_name = "Audio"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/audio.svg")
	event_color = Color("#fc6514")
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 0
	
	# maybe using setters is better for this scenario?
	# like doing:
	#set_name("Pepito Event")
	#set_color(Color.black)


func _execute() -> void:
	# I have no idea how this event works
	pass
