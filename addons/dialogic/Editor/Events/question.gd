tool
extends DialogicEvent

export(String) var node_path:String = "" # this probably will need a setter

# _init is the constructor
# is called everytime the resource is being created
# (including when the resource is loaded)
# ensuring to keep the same values everytime until
# you modify them
func _init() -> void:
	event_name = "Question"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/question.svg")
	event_color = Color("#9e77ec")
	event_category = Category.LOGIC
	event_sorting_index = 0


func _execute() -> void:
	# I have no idea how this event works
	pass
