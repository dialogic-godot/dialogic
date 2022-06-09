extends CanvasLayer

## FOR TESTING PURPOSES
func _ready():
	if DialogicUtil.get_setting('QuickTimelineTest', 'timeline_file'):
		DialogicGameHandler.start_timeline(DialogicUtil.get_setting('QuickTimelineTest', 'timeline_file'))
	else:
		DialogicGameHandler.start_timeline("res://timelines/Chapter1.dtl")
	DialogicGameHandler.connect("timeline_ended", get_tree(), 'quit')
