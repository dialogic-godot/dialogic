extends Node


func handle_event(event_data, dialog_node):
	""" 
		if you want to stop the user from progressing while this even is handled
		Valid states include:
		## IDLE - When nothing is happening
		## READY - When Dialogic already displayed the text on the screen
		## TYPING - While the editor is typing text
		## WAITING - Waiting a timer or something to finish
		## WAITING_INPUT - Waiting for player to answer a question
		## ANIMATING - While performing a dialog animation
	"""
	#dialog_node.set_state(state.WAITING_INPUT)
	
	pass # fill with event action
	
	# once you want to continue with the next event
	dialog_node._load_next_event()
	dialog_node.set_state(dialog_node.state.READY)
