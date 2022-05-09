tool
extends DialogicEvent

export(String) var node_path:String = "" # this probably will need a setter

# _init is the constructor
# is called everytime the resource is being created
# (including when the resource is loaded)
# ensuring to keep the same values everytime until
# you modify them
func _init() -> void:
	event_name = "Text"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/text-event.svg")
	event_color = Color("#ffffff")
	event_category = Category.MAIN
	event_sorting_index = 0
	
	# maybe using setters is better for this scenario?
	# like doing:
	#set_name("Pepito Event")
	#set_color(Color.black)


func _execute() -> void:
	# I have no idea how this event works
	pass


func _get_property_list() -> Array:
	var p_list = []
	p_list.append({
		"name":"text",
		"type":TYPE_STRING,
		"location": Location.HEADER
		})
	p_list.append({
		"name":"Testing int",
		"type":TYPE_INT,
		"location": Location.BODY
		})
	return p_list
