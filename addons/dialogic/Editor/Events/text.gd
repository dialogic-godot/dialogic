tool
extends DialogicEvent

#export(String) var node_path:String = "" # this probably will need a setter


var Text:String = "" setget set_text
var Character:DialogicCharacter

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

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	if Character:
		return Character.name+": "+Text
	return Text

## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string):
	if ":" in string:
		var char_name = string.get_slice(": ", 0)
		var character = DialogicUtil.guess_resource('.dch', char_name)
		if character:
			Character = load(character)
		else:
			Character = null
			print("When importing timeline, we couldn't identify what character you meant with ", char_name, ".")
		Text = string.split(": ", 1)[1]
	else:
		Character = null
		Text = string


func _get_property_list() -> Array:
	var p_list = []
	p_list.append({
		"name":"Character",
		"type":TYPE_OBJECT,
		"location": Location.HEADER,
		"usage":PROPERTY_USAGE_DEFAULT,
		"dialogic_type":DialogicValueType.Character,
		"hint_string":"Character:"
		})
	p_list.append({
		"name":"Text",
		"type":TYPE_STRING,
		"location": Location.BODY,
		"usage":PROPERTY_USAGE_DEFAULT,
		"dialogic_type":DialogicValueType.MultilineText,
		})
	
	return p_list

func set_text(new_text):
	Text = new_text
	emit_changed()
