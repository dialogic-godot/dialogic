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
	dialogic.current_state_info['theme'] = theme_name
	for theme_node in get_tree().get_nodes_in_group('dialogic_themes'):
		if theme_node.theme_name == theme_name:
			theme_node.show()
		else:
			theme_node.hide()
