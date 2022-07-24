extends Control


func _ready():
	var scene = load( DialogicUtil.get_project_setting('dialogic/editor/test_dialog_scene', 'res://addons/dialogic/Other/DefaultDialogNode.tscn')).instance()
	add_child(scene)
	
	randomize()
	var current_timeline = ProjectSettings.get_setting('dialogic/editor/current_timeline_path')
	Dialogic.start_timeline(current_timeline)
	Dialogic.connect("timeline_ended", get_tree(), 'quit')
	Dialogic.connect("signal_event", self, 'recieve_event_signal')
	Dialogic.connect("text_signal", self, 'recieve_text_signal')

func recieve_event_signal(argument):
	print("[Dialogic] Encountered a signal event: ", argument)

func recieve_text_signal(argument):
	print("[Dialogic] Encountered a signal in text: ", argument)
	
