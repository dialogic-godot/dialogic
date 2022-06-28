extends Control


func _ready():
	randomize()
	var current_timeline = ProjectSettings.get_setting('dialogic/current_timeline_path')
	print('ProjectSettings - dialogic/current_timeline_path: ', current_timeline)
	DialogicGameHandler.start_timeline(current_timeline)
	DialogicGameHandler.connect("timeline_ended", get_tree(), 'quit')
	DialogicGameHandler.connect("signal_event", self, 'recieve_event_signal')
	DialogicGameHandler.connect("text_signal", self, 'recieve_text_signal')

func recieve_event_signal(argument):
	print("[Dialogic] Encountered a signal event: ", argument)

func recieve_text_signal(argument):
	print("[Dialogic] Encountered a signal in text: ", argument)
	
