extends Node

func _ready():
	var timeline = DialogicResources.get_settings_value('QuickTimelineTest', 'timeline_file', '')
	var language = DialogicResources.get_settings_value('QuickTimelineTest', 'language', '')
	var dialog = Dialogic.start(timeline, '', "res://addons/dialogic/Nodes/DialogNode.tscn", true, language)
	dialog.connect('dialogic_signal', self, '_on_DialogNode_dialogic_signal')
	dialog.connect('timeline_end', self, '_on_DialogNode_timeline_end')
	add_child(dialog)

func _on_DialogNode_dialogic_signal(argument):
	print('Signal recieved. Argument: ', argument)

func _on_DialogNode_timeline_end(timeline):
	get_tree().quit()
