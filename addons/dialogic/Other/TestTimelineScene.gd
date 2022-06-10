extends Control


func _ready():
	var current_timeline = ProjectSettings.get_setting('dialogic/current_timeline_path')
	print('ProjectSettings - dialogic/current_timeline_path: ', current_timeline)
	DialogicGameHandler.start_timeline(current_timeline)
	DialogicGameHandler.connect("timeline_ended", get_tree(), 'quit')
