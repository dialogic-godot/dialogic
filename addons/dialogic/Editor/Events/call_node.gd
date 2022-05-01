extends DialogicEvent

export(String) var node_path:String = "" # this probably will need a setter

# _init is the constructor
# is called everytime the resource is being created
# (including when the resource is loaded)
# ensuring to keep the same values everytime until
# you modify them
func _init() -> void:
	event_name = "Call Node"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/call-node.svg")
	event_color = Color("#0ca5eb")
	event_category = Category.GODOT
	event_sorting_index = 1
	
	# maybe using setters is better for this scenario?
	# like doing:
	#set_name("Pepito Event")
	#set_color(Color.black)


func _execute() -> void:
	# I have no idea how this event works
	pass
