extends CanvasLayer

## FOR TESTING PURPOSES
func _ready():
	var current_timeline = ProjectSettings.get_setting('quick_timeline_test/timeline_file')
	if current_timeline:
		DialogicGameHandler.start_timeline(current_timeline)
	else:
		DialogicGameHandler.start_timeline("res://timelines/Chapter1.dtl")
	DialogicGameHandler.connect("timeline_ended", get_tree(), 'quit')
