extends Node

func _ready():
	var dialog = Dialogic.start(DialogicResources.get_settings_value('QuickTimelineTest', 'timeline_file', ''))
	dialog.connect('dialogic_signal', self, '_on_DialogNode_dialogic_signal')
	dialog.connect('timeline_end', self, '_on_DialogNode_timeline_end')
	add_child(dialog)

func _on_DialogNode_dialogic_signal(argument):
	print('Signal recieved. Argument: ', argument)

func _on_DialogNode_timeline_end(timeline):
	get_tree().quit()
