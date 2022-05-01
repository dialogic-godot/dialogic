tool
extends DialogicEvent

export(String) var node_path:String = "" # this probably will need a setter

# _init is the constructor
# is called everytime the resource is being created
# (including when the resource is loaded)
# ensuring to keep the same values everytime until
# you modify them
func _init() -> void:
	event_name = "Change Timeline"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/change-timeline.svg")
	event_color = Color("#12b76a")
	event_category = Category.TIMELINE
	event_sorting_index = 1


func _execute() -> void:
	# I have no idea how this event works
	pass
