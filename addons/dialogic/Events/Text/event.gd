tool
extends DialogicEvent
class_name DialogicTextEvent


var Text:String = ""
var Character:DialogicCharacter
var Portrait = ""

# _init is the constructor
# is called everytime the resource is being created
# (including when the resource is loaded)
# ensuring to keep the same values everytime until
# you modify them
func _init() -> void:
	event_name = "Text"
	event_color = Color("#2F80ED")
	event_category = Category.MAIN
	event_sorting_index = 0
	help_page_path = "https://dialogic.coppolaemilio.com/documentation/Events/000/"
	continue_at_end = false


func _execute() -> void:
	dialogic_game_handler.update_dialog_text(dialogic_game_handler.parse_variables(get_translated_text()))

	if Character:
		dialogic_game_handler.update_name_label(Character.name, Character.color)
		if Portrait:
			dialogic_game_handler.update_portrait(Character, Portrait)
	else:
		dialogic_game_handler.update_name_label("")
	while true:
		yield(dialogic_game_handler, "state_changed")
		if dialogic_game_handler.current_state == dialogic_game_handler.states.IDLE:
			break
	if dialogic_game_handler.is_question(dialogic_game_handler.current_event_idx):
		#print("QUESTION!")
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
func load_from_string_to_store(string:String):
	var reg = RegEx.new()
	reg.compile("((?<name>[^:()\\n]*)?(?=(\\([^()]*\\))?:)(\\((?<portrait>[^()]*)\\))?)?:?(?<text>[^\\n]+)")
	var result = reg.search(string)
	if result and !result.get_string('name').empty():
		var character = DialogicUtil.guess_resource('.dch', result.get_string('name').strip_edges())
		if character:
			Character = load(character)
		else:
			Character = null
			#print("When importing timeline, we couldn't identify what character you meant with ", result.get_string('name'), ".")
		if !result.get_string('portrait').empty():
			Portrait = result.get_string('portrait').strip_edges()
	Text = result.get_string('text').replace("<br>", "\n").trim_prefix(" ")
	

func is_valid_event_string(string):
	return true


func can_be_translated():
	return true
	
func get_original_translation_text():
	return Text

func build_event_editor():
	add_header_edit('Character', ValueType.Character, 'Character:')
	add_header_edit('Portrait', ValueType.Portrait, '')
	add_body_edit('Text', ValueType.MultilineText)
