extends DialogicSubsystem

## Subsystem that handles showing of input promts. 

## Signal that is fired when a confirmation button was pressed.
signal input_confirmed(input:String)
signal input_shown(info:Dictionary)


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	hide_text_input()


####################################################################################################
##					MAIN METHODS
####################################################################################################

func show_text_input(text:String = '', default:String = '', placeholder:String = '', allow_empty:bool = false) -> void:
	for node in get_tree().get_nodes_in_group('dialogic_text_input'):
		node.show()
		if node.has_method('set_allow_empty'): node.set_allow_empty(allow_empty)
		if node.has_method('set_text'): node.set_text(text)
		if node.has_method('set_default'): node.set_default(default)
		if node.has_method('set_placeholder'): node.set_placeholder(placeholder)
	input_shown.emit({'text':text, 'default':default, 'placeholder':placeholder, 'allow_empty':allow_empty})


func hide_text_input() -> void:
	for node in get_tree().get_nodes_in_group('dialogic_text_input'):
		node.hide()
