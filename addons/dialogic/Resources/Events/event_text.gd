tool
extends DialogicEvent
class_name DialogicTextEvent


var Text:String = "" setget set_text
var Character:DialogicCharacter
var Portrait = ""

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
	help_page_path = "https://dialogic.coppolaemilio.com/documentation/Events/000/"
	continue_at_end = false
	# maybe using setters is better for this scenario?
	# like doing:
	#set_name("Pepito Event")
	#set_color(Color.black)


func _execute() -> void:
	dialogic_game_handler.update_dialog_text(Text)
	if Character:
		dialogic_game_handler.update_name_label(Character.name, Character.color)
	else:
		dialogic_game_handler.update_name_label("")
	while true:
		yield(dialogic_game_handler, "state_changed")
		if dialogic_game_handler.current_state == dialogic_game_handler.states.IDLE:
			break
	if dialogic_game_handler.is_question(dialogic_game_handler.current_event_idx):
		print("QUESTION!")
		dialogic_game_handler.show_current_choices()
		dialogic_game_handler.current_state = dialogic_game_handler.states.AWAITING_CHOICE
	finish()


## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	if Character:
		if not Portrait.empty():
			return Character.name+" ("+Portrait+"): "+Text.replace("\n", "<br>")
		return Character.name+": "+Text.replace("\n", "<br>")
	return Text.replace("\n", "<br>")

## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string):
	var reg = RegEx.new()
	reg.compile("((?<name>[^:()\\n]*)?(?=(\\([^()]*\\))?:)(\\((?<portrait>[^()]*)\\))?)?:?(?<text>[^\\n]+)")
	var result = reg.search(string)
	if !result.get_string('name').empty():
		var character = DialogicUtil.guess_resource('.dch', result.get_string('name').strip_edges())
		if character:
			Character = load(character)
		else:
			Character = null
			print("When importing timeline, we couldn't identify what character you meant with ", result.get_string('name'), ".")
		#print(result.get_string('portrait'))
		if !result.get_string('portrait').empty():
			Portrait = result.get_string('portrait').strip_edges()
	Text = result.get_string('text').replace("<br>", "\n").trim_prefix(" ")
	

static func is_valid_event_string(string):
	return true

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
	p_list.append({
		"name":"Portrait",
		"type":TYPE_OBJECT,
		"location": Location.HEADER,
		"usage":PROPERTY_USAGE_DEFAULT,
		"dialogic_type":DialogicValueType.Portrait,
		})
	
	return p_list

func set_text(new_text):
	Text = new_text
	emit_changed()
