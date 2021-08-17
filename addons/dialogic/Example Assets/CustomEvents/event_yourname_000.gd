extends Node


func handle_event(event_data, dialog_node):
	## if you want to stop the user from progressing while this even is handled
	#dialog_node.waiting = true
	
	pass # fill with event action
	
	# once you want to continue with the next event
	dialog_node._load_next_event()
	dialog_node.waiting = false
