extends DialogicSubsystem

## Subsystem that manages showing and hiding style nodes.


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	change_style('')


func load_game_state():
	change_style(dialogic.current_state_info.get('style'))


####################################################################################################
##					MAIN METHODS
####################################################################################################

func change_style(style_name:String) -> void:
	var style_found: bool = false
	var last_style := ""
	dialogic.current_state_info['style'] = style_name
	for style_node in get_tree().get_nodes_in_group('dialogic_styles'):
		if style_node.style_name == style_name:
			style_node.show()
			style_found = true
		else:
			if style_node.visible:
				last_style = style_node.style_name
				style_node.hide()
	
	if (!style_found):
		for style_node in get_tree().get_nodes_in_group('dialogic_styles'):
			if style_node.style_name == last_style:
				style_node.show()
