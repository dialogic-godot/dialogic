extends DialogicSubsystem


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	change_theme('')

func load_game_state():
	change_theme(dialogic.current_state_info.get('theme'))

####################################################################################################
##					MAIN METHODS
####################################################################################################
func change_theme(theme_name):
	var theme_found: bool = false
	var last_theme = ""
	dialogic.current_state_info['theme'] = theme_name
	for theme_node in get_tree().get_nodes_in_group('dialogic_themes'):
		if theme_node.theme_name == theme_name:
			theme_node.show()
			theme_found = true
		else:
			if theme_node.visible:
				last_theme = theme_node.theme_name
				theme_node.hide()
			
	if (!theme_found):
		for theme_node in get_tree().get_nodes_in_group('dialogic_themes'):
			if theme_node.theme_name == last_theme:
				theme_node.show()
